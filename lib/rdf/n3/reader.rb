# coding: utf-8
require 'rdf/reader'
require 'ebnf'

module RDF::N3
  ##
  # A Notation-3/Turtle parser in Ruby
  #
  # N3 Parser, based in librdf version of predictiveParser.py
  # @see http://www.w3.org/2000/10/swap/grammar/predictiveParser.py
  # @see http://www.w3.org/2000/10/swap/grammar/n3-selectors.n3
  #
  # Separate pass to create branch_table from n3-selectors.n3
  #
  # This implementation uses distinguished variables for both universal and explicit existential variables (defined with `@forSome`). Variables created from blank nodes are non-distinguished. Distinguished existential variables are tracked using `$`, internally, as the RDF `query_pattern` logic looses details of the variable definition in solutions, where the variable is represented using a symbol.
  #
  # @todo
  # * Formulae as RDF::Query representations
  # * Formula expansion similar to SPARQL Construct
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Reader < RDF::Reader
    format Format

    include RDF::Util::Logger
    include EBNF::PEG::Parser
    include Meta
    include Terminals

    # Nodes used as Formulae graph names
    #
    # @return [Array<RDF::Node>]
    attr_reader :formulae

    # Allocated variables by formula
    #
    # @return [Hash{Symbol => RDF::Node}]
    attr_reader :variables

    ##
    # Initializes the N3 reader instance.
    #
    # @param  [IO, File, String] input
    #   the input stream to read
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (not supported by
    #   all readers)
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize parsed literals and URIs.
    # @option options [Boolean]  :intern       (true)
    #   whether to intern all parsed URIs
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all readers)
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [Error]:: Raises RDF::ReaderError if validating and an error is found
    def initialize(input = $stdin, **options, &block)
      super do
        input.rewind if input.respond_to?(:rewind)
        @input = input.respond_to?(:read) ? input : StringIO.new(input.to_s)
        @lineno = 0

        @memo = {}
        @keyword_mode = false
        @keywords = %w(a is of this has).map(&:freeze).freeze
        @productions = []
        @prod_data = []

        @formulae = []
        @label_uniquifier ||= "#{Random.new_seed}_000000"
        @bnodes = {}  # allocated bnodes by formula
        @variables = {}

        if options[:base_uri]
          progress("base_uri") { base_uri.inspect}
          namespace(nil, uri("#{base_uri}#"))
        end

        # Prepopulate operator namespaces unless validating
        unless validate?
          namespace(:crypto, RDF::N3::Crypto)
          namespace(:list, RDF::N3::List)
          namespace(:log, RDF::N3::Log)
          namespace(:math, RDF::N3::Math)
          namespace(:rei, RDF::N3::Rei)
          #namespace(:string, RDF::N3::String)
          namespace(:time, RDF::N3::Time)
        end
        progress("validate") {validate?.inspect}
        progress("canonicalize") {canonicalize?.inspect}
        progress("intern") {intern?.inspect}

        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, base_uri.to_s)
    end

    ##
    # Iterates the given block for each RDF statement in the input.
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        @callback = block
        parse(@input,
              :n3Doc,
              RDF::N3::Meta::RULES,
              whitespace:  WS,
              **@options
        ) do |context, *data|
          case context
          when :base_uri
            uri = data.first
            options[:base_uri] = process_uri(uri)

            # The empty prefix "" is by default , bound to "#" -- the local namespace of the file.
            # The parser behaves as though there were a
            #   @prefix : <#>.
            # just before the file.
            # This means that <#foo> can be written :foo and using @keywords one can reduce that to foo.

            namespace(nil, uri.to_s.match(/[\/\#]$/) ? base_uri : process_uri("#{uri}#"))
            debug("@base") {"@base=#{base_uri}"}
          end
        end

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_for(:each_statement)
    rescue EBNF::PEG::Parser::Error => e
      case e.message
      when /found "@kewords/
        raise RDF::ReaderError, "@keywords has been removed"
      else
        raise RDF::ReaderError, e.message
      end
    end

    ##
    # Iterates the given block for each RDF triple in the input.
    #
    # @yield  [subject, predicate, object]
    # @yieldparam [RDF::Resource] subject
    # @yieldparam [RDF::URI]      predicate
    # @yieldparam [RDF::Value]    object
    # @return [void]
    def each_triple
      if block_given?
        each_statement do |statement|
          yield(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end

    protected

    ##
    # Parser terminals and productions
    ##
    terminal(:BOOLEAN_LITERAL,                  %r{@?(?:true|false)}) do |value|
      RDF::Literal.new(value.start_with?('@') ? value[1..-1] : value,
                       datatype: RDF::XSD.boolean,
                       canonicalize: canonicalize?)
    end
    terminal(:IRIREF,                           IRIREF) {|value| process_uri(value[1..-2])}
    terminal(:PNAME_NS,                         PNAME_NS)
    terminal(:PNAME_LN,                         PNAME_LN) {|value| RDF::NTriples.unescape(value)}
    terminal(:BLANK_NODE_LABEL,                 BLANK_NODE_LABEL) {|value| bnode(value[2..-1])}
    terminal(:LANGTAG,                          LANGTAG) {|value| value[1..-1]}
    terminal(:INTEGER,                          INTEGER) {|value| RDF::Literal::Integer.new(value, canonicalize: canonicalize?)}
    terminal(:DECIMAL,                          DECIMAL) {|value| RDF::Literal::Decimal.new(value, canonicalize: canonicalize?)}
    terminal(:DOUBLE,                           DOUBLE) {|value| RDF::Literal::Double.new(value, canonicalize: canonicalize?)}
    terminal(:STRING_LITERAL_QUOTE,             STRING_LITERAL_QUOTE) do |value|
      RDF::NTriples.unescape(value[1..-2])
    end
    terminal(:STRING_LITERAL_SINGLE_QUOTE,      STRING_LITERAL_SINGLE_QUOTE) do |value|
      RDF::NTriples.unescape(value[1..-2])
    end
    terminal(:STRING_LITERAL_LONG_SINGLE_QUOTE, STRING_LITERAL_LONG_SINGLE_QUOTE) do |value|
      RDF::NTriples.unescape(value[3..-4])
    end
    terminal(:STRING_LITERAL_LONG_QUOTE,        STRING_LITERAL_LONG_QUOTE) do |value|
      RDF::NTriples.unescape(value[3..-4])
    end
    terminal(:ANON,                             ANON) {bnode}
    terminal(:QUICK_VAR_NAME,                   QUICK_VAR_NAME) {|value| univar(value[1..-1])}
    terminal(:BASE,                             BASE)
    terminal(:PREFIX,                           PREFIX)

    start_production(:n3Doc) do |data, block|
      formulae.push(nil)
    end

    # Cleanup packrat storage after successfully parsing
    #
    # (rule _n3Doc_1 "1.1" (alt _n3Doc_2 sparqlDirective))
    production(:_n3Doc_1, clear_packrat: true) {|value| value}

    # (rule sparqlBase "5" (seq BASE IRIREF))
    production(:sparqlBase) do |value, data, block|
      block.call(:base_uri, value.last[:IRIREF])
    end

    # (rule sparqlPrefix "6" (seq PREFIX PNAME_NS IRIREF))
    production(:sparqlPrefix) do |value|
      namespace(value[1][:PNAME_NS][0..-2], value.last[:IRIREF])
    end

    # (rule prefixID "7" (seq "@prefix" PNAME_NS IRIREF))
    production(:prefixID) do |value|
      namespace(value[1][:PNAME_NS][0..-2], value.last[:IRIREF])
    end

    # (rule base "8" (seq "@base" IRIREF))
    production(:base) do |value, data, block|
      block.call(:base_uri, value.last[:IRIREF])
    end

    # (rule triples "9" (seq _triples_1 _triples_2))
    production(:triples) {|value| value}
    # (rule _triples_1 "9.1" (alt subject blankNodePropertyList))
    production(:_triples_1) do |value, data|
      debug("triples") {"subject: #{data[:subject]}"}
      prod_data[:subject] = data[:subject]
    end
    # (rule _triples_2 "9.2" (opt predicateObjectList))
    start_production(:_triples_2) do |data|
      debug("triples") {"subject: #{data[:subject]}"}
      data[:subject] = prod_data[:subject]
      nil
    end

    # (rule predicateObjectList "10" (seq verb objectList _predicateObjectList_1))
    start_production(:predicateObjectList, as_hash: true) do |data|
      # placed here by `subject` or `blankNodePropertyList`
      data[:subject] = prod_data[:subject]
    end

    # (rule objectList "11" (seq object _objectList_1))
    start_production(:objectList) do |data|
      subject, predicate = prod_data[:subject], prod_data[:verb]
      debug("objectList(start)") {"subject: #{subject.inspect}, predicate: #{predicate.inspect}"}
    end
    production(:objectList) do |value|
      subject, predicate = prod_data[:subject], prod_data[:verb]
      debug("objectList") {"subject: #{subject.inspect}, predicate: #{predicate.inspect}"}
      objects = Array(value.last[:_objectList_1]).unshift(value.first[:object])

      # Emit triples with given subject and verb for each object
      objects.each do |object|
        if prod_data[:invert]
          add_statement(:objectList, object, predicate, subject)
        else
          add_statement(:objectList, subject, predicate, object)
        end
      end
    end
    # (rule _objectList_1 "11.1" (star _objectList_2))
    # (rule _objectList_2 "11.2" (seq "," object))
    production(:_objectList_2) {|value| value.last[:object]}

    # (rule verb "12" (alt predicate "a" "@a" _verb_1 _verb_2 _verb_3 _verb_4 "=" "<=" "=>"))
    # Adds verb to prod_data for objectList
    production(:verb) do |value, data|
      prod_data[:verb] = case value
      when RDF::Term
        prod_data[:invert] = data[:invert]
        value
      when 'a', '@a' then RDF.type
      when '=' then RDF::OWL.sameAs
      when '=>' then RDF::N3::Log.implies
      when '<='
        prod_data[:invert] = true
        RDF::N3::Log.implies
      when Array  # forms of has and is xxx of
        if value.first[:has] || value.first[:@has]
          value[1][:expression]
        elsif value.first[:is] || value.first[:@is]
          prod_data[:invert] = true
          value[1][:expression]
        end
      end
    end

    #  (rule subject "13" (seq expression))
    production(:subject) do |value|
      # Put in prod_data, so it's available to predicateObjectList
      prod_data[:subject] = value.last[:expression]
    end

    # (rule predicate "14" (alt expression _predicate_1))
    production(:predicate) do |value, data|
      prod_data[:invert] = data[:invert]
      value
    end
    # (rule _predicate_1 "14.1" (seq "^" expression))
    production(:_predicate_1) do |value|
      prod_data[:invert] = true
      value.last[:expression]
    end
    

    #  (rule object "15" (seq expression))
    production(:object) do |value|
      value.last[:expression]
    end

    # (rule expression "16" (seq path))
    production(:expression) do |value|
      path = value.last[:path]
      case path
      when Hash # path
        # Result is a bnode
        process_path(path)
      else
        path
      end
    end

    #  (rule path "17" (seq pathItem _path_1))
    start_production(:path, as_hash: true)
    production(:path) do |value, data|
      if value[:_path_1]
        {
          pathitem:   value[:pathItem],
          direction:  value[:_path_1][:"!"] ? :forward : :reverse,
          pathtail:   value[:_path_1][:path]
        }
      else
        value[:pathItem]
      end
    end
    # (rule _path_3 "17.3" (seq "!" path))
    start_production(:_path_3, as_hash: true)
    # (rule _path_4 "17.4" (seq "^" path))
    start_production(:_path_4, as_hash: true)
  
    # (rule blankNodePropertyList "20" (seq "[" _blankNodePropertyList_1 "]"))
    production(:blankNodePropertyList) {|value| value[1][:_blankNodePropertyList_1]}
    # (rule _blankNodePropertyList_1 "20.1" (opt predicateObjectList))
    start_production(:_blankNodePropertyList_1) {|data| data[:subject] = bnode}
    # Returns the blank node subject
    production(:_blankNodePropertyList_1) do |value, data|
      data[:subject]
    end

    # (rule collection "21" (seq "(" _collection_1 ")"))
    production(:collection) {|value| value[1][:_collection_1]}
    # (rule _collection_1 "21.1" (star object))
    production(:_collection_1) do |value|
      list = RDF::List[*value]
      list.each_statement do |statement|
        next if statement.predicate == RDF.type && statement.object == RDF.List
        add_statement(":collection", statement.subject, statement.predicate, statement.object)
      end
      list.subject
    end

    # A new formula, push on a node as a named graph
    #
    # (rule formula "22" (seq "{" _formula_1 "}"))
    production(:formula) {|value| value[1][:_formula_1]}

    start_production(:_formula_1) do |data|
      node = RDF::Node.new(".form_#{unique_label}")
      formulae.push(node)
      debug(:formula) {"id: #{node}, depth: #{formulae.length}"}

      # Promote variables defined on the earlier formula to this formula
      variables[node] = {}
      variables.fetch(formulae[-2], {}).each do |name, var|
        variables[node][name] = var
      end
    end

    # Pop off the formula
    production(:_formula_1) do |value|
      # Result is the BNode associated with the formula
      debug(:formula) {"pop: #{formulae.last}, depth: #{formulae.length}"}
      formulae.pop
    end
    

    #  (rule rdfLiteral "25" (seq STRING _rdfLiteral_1))
    production(:rdfLiteral) do |value|
      str = value.first[:STRING]
      lang = value.last[:_rdfLiteral_1].to_sym if value.last[:_rdfLiteral_1].is_a?(String)
      datatype = value.last[:_rdfLiteral_1] if value.last[:_rdfLiteral_1].is_a?(RDF::URI)
      RDF::Literal(str, language: lang, datatype: datatype, canonicalize: canonicalize?)
    end
    # (rule _rdfLiteral_3 "25.3" (seq "^^" iri))
    production(:_rdfLiteral_3) {|value| value.last[:iri]}

    # (rule iriList "27" (seq iri _iriList_1))
    production(:iriList) do |value|
      Array(value.last[:_iriList_1]).unshift(value.first[:iri])
    end
    #  (rule _iriList_2 "27.2" (seq "," iri))
    production(:_iriList_2) {|value| value.last[:iri]}

    # (rule prefixedName "28" (alt PNAME_LN PNAME_NS))
    production(:prefixedName) do |value|
      process_pname(value)
    end

    # There is a also a shorthand syntax ?x which is the same as :x except that it implies that x is universally quantified not in the formula but in its parent formula
    #
    # (rule quickVar "30" (seq QUICK_VAR_NAME))
    production(:quickVar) do |value|
      var = value.first[:QUICK_VAR_NAME]
      add_var_to_formula(formulae[-2], var, var)
      # Also add var to this formula
      add_var_to_formula(formulae.last, var, var)
      var
    end

    # Apart from the set of statements, a formula also has a set of URIs of symbols which are universally quantified,
    # and a set of URIs of symbols which are existentially quantified.
    # Variables are then in general symbols which have been quantified.
    #
    # Here we allocate a variable (making up a name) and record with the defining formula. Quantification is done
    # when the formula is completed against all in-scope variables
    #
    # (rule existential "31" (seq "@forSome" iriList))
    production(:existential) do |value|
      value.last[:iriList].each do |iri|
        var = univar(iri, true)
        add_var_to_formula(formulae.last, iri, var)
      end
    end

    # Apart from the set of statements, a formula also has a set of URIs of symbols which are universally quantified,
    # and a set of URIs of symbols which are existentially quantified.
    # Variables are then in general symbols which have been quantified.
    #
    # Here we allocate a variable (making up a name) and record with the defining formula. Quantification is done
    # when the formula is completed against all in-scope variables
    #
    #  (rule universal "32" (seq "@forAll" iriList))
    production(:universal) do |value|
      value.last[:iriList].each do |iri|
        add_var_to_formula(formulae.last, iri, univar(iri))
      end
    end

  private

    ###################
    # Utility Functions
    ###################

    # Process a path, such as:
    #   :a!:b means [is :b of :a] => :a :b []
    #   :a^:b means [:b :a]       => [] :b :a
    #
    # Create triple and return property used for next iteration
    #
    # Result is last created bnode
    def process_path(path)
      pathitem, direction, pathtail = path[:pathitem], path[:direction], path[:pathtail]
      debug("process_path") {path.inspect}

      while pathtail
        bnode = RDF::Node.new
        pred = pathtail.is_a?(RDF::Term) ? pathtail : pathtail[:pathitem]
        if direction == :reverse
          add_statement("process_path(reverse)", bnode, pred, pathitem)
        else
          add_statement("process_path(forward)", pathitem, pred, bnode)
        end
        pathitem = bnode
        direction = pathtail[:direction] if pathtail.is_a?(Hash)
        pathtail = pathtail.is_a?(Hash) && pathtail[:pathtail]
      end
      pathitem
    end

    def process_uri(uri)
      uri(base_uri, RDF::NTriples.unescape(uri.to_s))
    end

    def process_pname(value)
      prefix, name = value.split(":")

      uri = if prefix(prefix)
        debug('process_pname(ns)') {"#{prefix(prefix)}, #{name}"}
        ns(prefix, name)
      else
        debug('process_pname(default_ns)', name)
        namespace(nil, uri("#{base_uri}#")) unless prefix(nil)
        ns(nil, name)
      end
      debug('process_pname') {uri.inspect}
      uri
    end

    # Keep track of allocated BNodes. Blank nodes are allocated to the formula.
    def bnode(label = nil)
      if label
        value = "#{label}_#{unique_label}"
        (@bnodes[@formulae.last] ||= {})[label.to_s] ||= RDF::Node.new(value)
      else
        RDF::Node.new
      end
    end

    def univar(label, existential = false)
      # Label using any provided label, followed by seed, followed by incrementing index
      value = "#{label}_#{unique_label}"
      RDF::Query::Variable.new(value, existential: existential)
    end

    # add a pattern or statement
    #
    # @param [any] node string for showing graph_name
    # @param [RDF::Term] subject the subject of the statement
    # @param [RDF::URI] predicate the predicate of the statement
    # @param [RDF::Term] object the object of the statement
    # @return [Statement] Added statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_statement(node, subject, predicate, object)
      statement = if @formulae.last
        # It's a pattern in a formula
        RDF::Query::Pattern.new(subject, predicate, object, graph_name: @formulae.last)
      else
        RDF::Statement(subject, predicate, object)
      end
      debug("statement(#{node})") {statement.to_s}
      error("statement(#{node})", "Statement is invalid: #{statement.inspect}") if validate? && statement.invalid?
      @callback.call(statement)
    end

    def namespace(prefix, uri)
      uri = uri.to_s
      if uri == '#'
        uri = prefix(nil).to_s + '#'
      end
      debug("namespace") {"'#{prefix}' <#{uri}>"}
      prefix(prefix, uri(uri))
    end

    # Create URIs
    def uri(value, append = nil)
      value = RDF::URI(value)
      value = value.join(append) if append
      value.validate! if validate? && value.respond_to?(:validate)
      value.canonicalize! if canonicalize?
      value = RDF::URI.intern(value) if intern?

      # Variable substitution for in-scope variables. Variables are in scope if they are defined in anthing other than the current formula
      var = find_var(@formulae.last, value)
      value = var if var

      value
    end

    # Decode a PName
    def ns(prefix = nil, suffix = nil)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug("ns") {"base: '#{base}', suffix: '#{suffix}'"}
      uri(base + suffix.to_s)
    end

    # Returns a unique label
    def unique_label
      label, @label_uniquifier = @label_uniquifier, @label_uniquifier.succ
      label
    end

    # Find any variable that may be defined in the formula identified by `bn`
    # @param [RDF::Node] sym name of formula
    # @param [#to_s] name
    # @return [RDF::Query::Variable]
    def find_var(sym, name)
      (variables[sym] ||= {})[name.to_s]
    end

    # Add a variable to the formula identified by `bn`, returning the variable. Useful as an LRU for variable name lookups
    # @param [RDF::Node] bn name of formula
    # @param [#to_s] name of variable for lookup
    # @param [RDF::Query::Variable] var
    # @return [RDF::Query::Variable]
    def add_var_to_formula(bn, name, var)
      (variables[bn] ||= {})[name.to_s] = var
    end
  end
end
