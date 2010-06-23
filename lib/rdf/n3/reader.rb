require 'treetop'

Treetop.load(File.join(File.dirname(__FILE__), "reader", "n3_grammar"))

module RDF::N3
  ##
  # A Notation-3/Turtle parser in Ruby
  #
  # @author [Gregg Kellogg](http://kellogg-assoc.com/)
  class Reader < RDF::Reader
    format Format

    N3_KEYWORDS = %w(a is of has keywords prefix base true false forSome forAny)

    NC_REGEXP = Regexp.new(
      %{^
        (?!\\\\u0301)             # &#x301; is a non-spacing acute accent.
                                  # It is legal within an XML Name, but not as the first character.
        (  [a-zA-Z_]
         | \\\\u[0-9a-fA-F]
        )
        (  [0-9a-zA-Z_\.-]
         | \\\\u([0-9a-fA-F]{4})
        )*
      $},
      Regexp::EXTENDED)
  
    ##
    # Initializes the N3 reader instance.
    #
    # @param  [IO, File, String]       input
    # @option options [Array] :debug Array to place debug messages
    # @option options [Boolean] :strict Raise Error if true, continue with lax parsing, otherwise
    # @option options [Boolean] :base_uri (nil) Base URI to use for relative URIs.
    # @return [reader]
    # @yield  [reader]
    # @yieldparam [Reader] reader
    # @raise [Error]:: Raises RDF::ReaderError if _strict_
    def initialize(input = $stdin, options = {}, &block)
      super do
        @debug = options[:debug]
        @strict = options[:strict]
        @uri_mappings = {}
        @uri = uri(options[:base_uri], nil, true)

        @doc = input.respond_to?(:read) ? (input.rewind; input.read) : input
        @default_ns = uri("#{options[:base_uri]}#", nil, false) if @uri
        add_debug("@default_ns", "#{@default_ns.inspect}")
        
        block.call(self) if block_given?
      end
    end

    ##
    # Iterates the given block for each RDF statement in the input.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      @callback = block

      parser = N3GrammerParser.new
      document = parser.parse(@doc)
      unless document
        puts parser.inspect if $DEBUG
        reason = parser.failure_reason
        raise RDF::ReaderError, reason
      end

      process_statements(document)
    end

    ##
    # Iterates the given block for each RDF triple in the input.
    #
    # @yield  [subject, predicate, object]
    # @yieldparam [RDF::Resource] subject
    # @yieldparam [RDF::URI]      predicate
    # @yieldparam [RDF::Value]    object
    # @return [void]
    def each_triple(&block)
      each_statement do |statement|
        block.call(*statement.to_triple)
      end
    end
    
    private

    # Keep track of allocated BNodes
    def bnode(value = nil)
      @bnode_cache ||= {}
      @bnode_cache[value.to_s] ||= RDF::Node.new(value)
    end

    # Add debug event to debug array, if specified
    #
    # @param [XML Node, any] node:: XML Node or string for showing context
    # @param [String] message::
    def add_debug(node, message)
      puts "#{node}: #{message}" if $DEBUG
      @debug << "#{node}: #{message}" if @debug.is_a?(Array)
    end

    # add a statement, object can be literal or URI or bnode
    #
    # @param [Nokogiri::XML::Node, any] node:: XML Node or string for showing context
    # @param [URI, Node] subject:: the subject of the statement
    # @param [URI] predicate:: the predicate of the statement
    # @param [URI, Node, Literal] object:: the object of the statement
    # @return [Statement]:: Added statement
    # @raise [RDF::ReaderError]:: Checks parameter types and raises if they are incorrect if parsing mode is _strict_.
    def add_triple(node, subject, predicate, object)
      statement = RDF::Statement.new(subject, predicate, object)
      add_debug(node, "statement: #{statement}")
      @callback.call(statement)
    end

    def namespace(uri, prefix)
      uri = uri.to_s
      if uri == "#"
        uri = @default_ns
      elsif !uri.match(/[\/\#]$/)
        uri += "#"
      end
      add_debug("namesspace", "'#{prefix}' <#{uri}>")
      @uri_mappings[prefix] = RDF::URI.intern(uri)
    end

    def process_statements(document)
      document.elements.find_all do |e|
        s = e.elements.first
        add_debug(*s.info("process_statements"))
        
        if s.respond_to?(:subject)
          subject = process_expression(s.subject)
          add_debug(*s.info("process_statements(#{subject})"))
          properties = process_properties(s.property_list)
          properties.each do |p|
            predicate = process_verb(p.verb)
            add_debug(*p.info("process_statements(#{subject}, #{predicate})"))
            raise RDF::ReaderError, %Q(Illegal statment: "#{predicate}" missing object) unless p.respond_to?(:object_list)
            objects = process_objects(p.object_list)
            objects.each do |object|
              if p.verb.respond_to?(:invert)
                add_triple("statement", object, predicate, subject)
              else
                add_triple("statement", subject, predicate, object)
              end
            end
          end
        elsif s.respond_to?(:anonnode)
          process_anonnode(s)
        elsif s.respond_to?(:pathitem)
          process_path(s)
        elsif s.respond_to?(:declaration)
          if s.respond_to?(:nprefix)
            add_debug(*s.info("process_statements(namespace)"))
            keyword_check("prefix") if s.text_value.index("prefix") == 0
            uri = process_uri(s.explicituri.uri, false)
            namespace(uri, s.nprefix.text_value)
          elsif s.respond_to?(:base)
            add_debug(*s.info("process_statements(base)"))
            keyword_check("base") if s.text_value.index("base") == 0
            # Base, set or update document URI
            uri = s.explicituri.uri.text_value
            @default_ns = process_uri(uri, false)  # Don't normalize
            add_debug("@default_ns", "#{@default_ns.inspect}")
            @uri = process_uri(uri)
            add_debug("@base", "#{@uri}")
            @uri
          elsif s.respond_to?(:keywords)
            add_debug(*s.info("process_statements(keywords)"))
            keyword_check("keywords") if s.text_value.index("keywords") == 0
            @keywords = process_barename_csl(s.barename_csl) ||[]
            add_debug("@keywords", @keywords.inspect)
            if (@keywords & N3_KEYWORDS) != @keywords
              raise RDF::ReaderError, "undefined keywords used: #{(@keywords - N3_KEYWORDS).to_sentence}" if @strict
            end
          end
        end
      end
    end
    
    def process_barename_csl(list)
      #add_debug(*list.info("process_barename_csl(list)"))
      res = [list.barename.text_value] if list.respond_to?(:barename)
      rest = process_barename_csl(list.barename_csl_tail) if list.respond_to?(:barename_csl_tail)
      rest ? res + rest : res
    end

    def process_anonnode(anonnode)
      add_debug(*anonnode.info("process_anonnode"))
      bnode = RDF::Node.new
      
      if anonnode.respond_to?(:property_list)
        properties = process_properties(anonnode.property_list)
        properties.each do |p|
          predicate = process_verb(p.verb)
          add_debug(*p.info("anonnode[#{predicate}]"))
          objects = process_objects(p.object_list)
          objects.each { |object| add_triple("anonnode", bnode, predicate, object) }
        end
      elsif anonnode.respond_to?(:path_list)
        objects = process_objects(anonnode.path_list)
        last = objects.pop
        first_bnode = bnode
        objects.each do |object|
          add_triple("anonnode", first_bnode, RDF.first, object)
          rest_bnode = RDF::Node.new
          add_triple("anonnode", first_bnode, RDF.rest, rest_bnode)
          first_bnode = rest_bnode
        end
        if last
          add_triple("anonnode", first_bnode, RDF.first, last)
          add_triple("anonnode", first_bnode, RDF.rest, RDF.nil)
        else
          bnode = RDF.nil
        end
      end
      bnode
    end

    def process_verb(verb)
      add_debug(*verb.info("process_verb"))
      case verb.text_value
      when "a"
        # If "a" is a keyword, then it's rdf:type, otherwise it's expanded from the default namespace
        if @keywords.nil? || @keywords.include?("a")
          RDF.type
        else
          build_uri("a")
        end
      when "@a"           then RDF.type
      when "="            then RDF::OWL.sameAs
      when "=>"           then RDF::LOG.implies
      when "<="           then RDF::LOG.implies
      when /^(@?is)\s+.*\s+(@?of)$/
        keyword_check("is") if $1 == "is"
        keyword_check("of") if $2 == "of"
        process_expression(verb.prop)
      when /^has\s+/
        keyword_check("has")
        process_expression(verb.prop)
      else
        if verb.respond_to?(:prop)
          process_expression(verb.prop)
        else
          process_expression(verb)
        end
      end
    end

    def process_expression(expression)
      if expression.respond_to?(:pathitem) && expression.respond_to?(:expression)
        add_debug(*expression.info("process_expression(pathitem && expression)"))
        process_path(expression)  # Returns last object in chain
      elsif expression.respond_to?(:uri)
        add_debug(*expression.info("process_expression(uri)"))
        process_uri(expression.uri)
      elsif expression.respond_to?(:localname)
        add_debug(*expression.info("process_expression(localname)"))
        build_uri(expression)
      elsif expression.respond_to?(:anonnode)
        add_debug(*expression.info("process_expression(anonnode)"))
        process_anonnode(expression)
      elsif expression.respond_to?(:literal)
        add_debug(*expression.info("process_expression(literal)"))
        process_literal(expression)
      elsif expression.respond_to?(:numericliteral)
        add_debug(*expression.info("process_expression(numericliteral)"))
        process_numeric_literal(expression)
      elsif expression.respond_to?(:boolean)
        add_debug(*expression.info("process_expression(boolean)"))
        barename = expression.text_value.to_s
        if @keywords && !@keywords.include?(barename)
          build_uri(barename)
        else
          RDF::Literal.new(barename.delete("@"), :datatype => RDF::XSD.boolean)
        end
      elsif expression.respond_to?(:barename)
        add_debug(*expression.info("process_expression(barename)"))
        barename = expression.text_value.to_s
        
        # Should only happen if @keywords is defined, and text_value is not a defined keyword
        case barename
        when "true"   then RDF::Literal.new("true", :datatype => RDF::XSD.boolean)
        when "false"  then RDF::Literal.new("false", :datatype => RDF::XSD.boolean)
        else
          # create URI using barename, unless it's in defined set, in which case it's an error
          raise RDF::ReaderError, %Q(Keyword "#{barename}" used as expression) if @keywords && @keywords.include?(barename)
          build_uri(barename)
        end
      else
        add_debug(*expression.info("process_expression(else)"))
        build_uri(expression)
      end
    end

    # Process a path, such as:
    #   :a.:b means [is :b of :a]
    #   :a!:b means [is :b of :a]
    #   :a^:b means [:b :a]
    #
    # Elements may be strug together, with the last element the verb applied to the previous expression:
    #   :a.:b.:c means [is :c of [ is :b of :a]]
    #   :a!:b^:c meands [:c [ is :b of :a]]
    def process_path(path)
      add_debug(*path.info("process_path"))

      object = process_expression(path.pathitem)
      
      # Create a list of direction/predicate pairs
      path_list = process_path_list(path.expression, path.respond_to?(:reverse))
      #puts path_list.inspect
      # Now we should have the following
      # [
      #   [:forward, b]
      #   [:forward, c]
      # ]
      path_list.each do |p|
        reverse, pred = p
        bnode = RDF::Node.new
        if reverse
          add_triple("path(#{reverse})", bnode, pred, object)
        else
          add_triple("path(#{reverse})", object, pred, bnode)
        end
        object = bnode
      end
      object
    end

    # Returns array of [:forward/:reverse, element] pairs
    def process_path_list(path, reverse)
      add_debug(*path.info("process_path_list(#{reverse})"))
      if path.respond_to?(:pathitem)
        [[reverse, process_expression(path.pathitem)]] + process_path_list(path.expression, path.respond_to?(:reverse))
      else
        [[reverse, process_expression(path)]]
      end
    end
    
    def process_uri(uri, normalize = true)
      uri = uri.text_value if uri.respond_to?(:text_value)
      uri(@uri, uri.rdf_escape, normalize)
    end
    
    def process_properties(properties)
      add_debug(*properties.info("process_properties"))
      result = []
      result << properties if properties.respond_to?(:verb)
      result << process_properties(properties.property_list) if properties.respond_to?(:property_list)
      result.flatten
    end

    def process_objects(objects)
      add_debug(*objects.info("process_objects"))
      result = []
      if objects.respond_to?(:object)
        result << process_expression(objects.object)
      elsif objects.respond_to?(:pathitem)
        result << process_expression(objects)
      elsif objects.respond_to?(:expression)
        result << process_expression(objects.expression)
        result << process_objects(objects.path_list) if objects.respond_to?(:path_list)
      elsif !objects.text_value.empty? || objects.respond_to?(:nprefix)
        result << process_expression(objects)
      end
      result << process_objects(objects.object_list) if objects.respond_to?(:object_list)
      result.flatten
    end

    def process_literal(object)
      add_debug(*object.info("process_literal"))
      encoding, language = nil, nil
      string, type = object.elements

      unless type.elements.nil?
        #puts type.elements.inspect
        if (type.elements[0].text_value=='@')
          language = type.elements[1].text_value
        else
          encoding = process_expression(type.elements[1])
        end
      end

      # Evaluate text_value to remove redundant escapes
      #puts string.elements[1].text_value.dump
      lit = RDF::Literal.new(string.elements[1].text_value.rdf_unescape, :language => language, :datatype => encoding)
      raise RDF::ReaderError, %(Typed literal has an invalid lexical value: #{encoding.to_s} "#{lit.value}") if @strict && !lit.valid?
      lit
    end
    
    def process_numeric_literal(object)
      add_debug(*object.info("process_numeric_literal"))

      RDF::Literal.new(object.text_value.rdf_unescape, :datatype => RDF::XSD[object.numericliteral])
    end
    
    def build_uri(expression)
      prefix = expression.respond_to?(:nprefix) ? expression.nprefix.text_value.to_s : ""
      localname = expression.localname.text_value if expression.respond_to?(:localname)
      localname ||= (expression.respond_to?(:text_value) ? expression.text_value : expression).to_s.sub(/^:/, "")
      localname = nil if localname.empty? # In N3/Turtle "_:" is not named

      if expression.respond_to?(:info)
        add_debug(*expression.info("build_uri(#{prefix.inspect}, #{localname.inspect})"))
      else
        add_debug("", "build_uri(#{prefix.inspect}, #{localname.inspect})")
      end

      uri = if @uri_mappings[prefix]
        add_debug(*expression.info("build_uri: (ns): #{@uri_mappings[prefix]}, #{localname.to_s.rdf_escape}")) if expression.respond_to?(:info)
        ns(prefix, localname.to_s.rdf_escape)
      elsif prefix == '_'
        add_debug(*expression.info("build_uri: (bnode)")) if expression.respond_to?(:info)
        bnode(localname)
      elsif prefix == "rdf"
        add_debug(*expression.info("build_uri: (rdf)")) if expression.respond_to?(:info)
        # A special case
        RDF::RDF[localname.to_s.rdf_escape]
      elsif prefix == "xsd"
        add_debug(*expression.info("build_uri: (xsd)")) if expression.respond_to?(:info)
        # A special case
        RDF::XSD[localname.to_s.rdf_escape]
      else
        add_debug(*expression.info("build_uri: (default_ns)")) if expression.respond_to?(:info)
        @default_ns ||= uri("#{@uri}#", nil)
        ns(nil, localname.to_s.rdf_escape)
      end
      add_debug(*expression.info("build_uri: #{uri.inspect}")) if expression.respond_to?(:info)
      uri
    end
    
    # Is this an allowable keyword?
    def keyword_check(kw)
      unless (@keywords || %w(a is of has)).include?(kw)
        raise RDF::ReaderError, "unqualified keyword '#{kw}' used without @keyword directive" if @strict
      end
    end
    
    # Create normalized or unnormalized URIs
    def uri(value, append, normalize = true)
      value = value.to_s.sub(/\#$/, "") if normalize
      value = case value
      when Addressable::URI then value
      else Addressable::URI.parse(value.to_s)
      end
      
      value = value.join(append) if append
      if normalize
        value.normalize!
      end
      RDF::URI.intern(value)
    end
    
    def ns(prefix, suffix)
      prefix = prefix.nil? ? @default_ns.to_s : @uri_mappings[prefix].to_s
      suffix = suffix.to_s.sub(/^\#/, "") if prefix.index("#")
      RDF::URI.intern(prefix + suffix)
    end
  end
end

module Treetop
  module Runtime
    class SyntaxNode
      # Brief information about a syntax node
      def info(ctx = "")
        m = self.singleton_methods(true)
        if m.empty?
          ["@#{self.interval.first}", "#{ctx}['#{self.text_value}']"]
        else
          ["@#{self.interval.first}", "#{ctx}[" +
          self.singleton_methods(true).map do |mm|
            v = self.send(mm)
            v = v.text_value if v.is_a?(SyntaxNode)
            "#{mm}='#{v}'"
          end.join(", ") +
          "]"]
        end
      end
    end
  end
end
