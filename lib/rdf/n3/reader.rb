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
  # @todo
  # Existentials, Universals and Formulae
  #
  # @author [Gregg Kellogg](http://kellogg-assoc.com/)
  class Reader < RDF::Reader
    format Format

    include Meta
    include Parser
    
    N3_KEYWORDS = %w(a is of has keywords prefix base true false forSome forAny)

    # FIXME: temporary patch until fixed in RDF.rb
    # Allow for nil prefix mapping
    def prefix(name, uri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      uri.nil? ? prefixes[name] : prefixes[name] = (uri.respond_to?(:to_sym) ? uri.to_sym : uri.to_s.to_sym)
    end

    ##
    # Initializes the N3 reader instance.
    #
    # @param  [IO, File, String] input
    #   the input stream to read
    # @option options [Array] :debug
    #   Array to place debug messages
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (not supported by
    #   all readers)
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize parsed literals
    # @option options [Boolean]  :intern       (true)
    #   whether to intern all parsed URIs
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all readers)
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [Error]:: Raises RDF::ReaderError if _validate_
    def initialize(input = $stdin, options = {}, &block)
      super do
        @uri = uri(options[:base_uri]) if options[:base_uri]

        @input = input.respond_to?(:read) ? (input.rewind; input) : StringIO.new(input.to_s)
        @lineno = 0
        readline  # Prime the pump
        
        @memo = {}
        @keyword_mode = false
        @keywords = %w(a is of this has)
        @productions = []
        @prod_data = []

        @branches = BRANCHES # Get from meta class
        @regexps = REGEXPS # Get from meta class
        
        @formulae = []    # Nodes used as Formluae context identifiers

        if @uri
          add_debug("@uri", "#{@uri.inspect}")
          namespace(nil, uri("#{options[:base_uri]}#"))
        end
        add_debug("validate", "#{validate?.inspect}")
        add_debug("canonicalize", "#{canonicalize?.inspect}")
        add_debug("intern", "#{intern?.inspect}")

        # Prefixes that may be used without being defined
        #prefix(:rdf, RDF.to_uri.to_s)
        #prefix(:xsd, RDF::XSD.to_uri.to_s)

        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
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

      parse(START.to_sym)
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
    
    protected
    # Start of production
    def onStart(prod)
      handler = "#{prod}Start".to_sym
      add_debug("#{handler}(#{respond_to?(handler)})", prod)
      @productions << prod
      send(handler, prod) if respond_to?(handler)
    end

    # End of production
    def onFinish
      prod = @productions.pop()
      handler = "#{prod}Finish".to_sym
      add_debug("#{handler}(#{respond_to?(handler)})", "#{prod}: #{@prod_data.last.inspect}")
      send(handler) if respond_to?(handler)
    end

    # Process of a token
    def onToken(prod, tok)
      unless @productions.empty?
        parentProd = @productions.last
        handler = "#{parentProd}Token".to_sym
        add_debug("#{handler}(#{respond_to?(handler)})", "#{prod}, #{tok}: #{@prod_data.last.inspect}")
        send(handler, prod, tok) if respond_to?(handler)
      else
        error("Token has no parent production")
      end
    end
    
    def booleanToken(prod, tok)
      lit = RDF::Literal.new(tok.delete("@"), :datatype => RDF::XSD.boolean, :validate => validate?, :canonicalize => true)
      add_prod_data(:literal, lit)
    end
    
    def declarationStart(prod)
      @prod_data << {}
    end
    
    def declarationToken(prod, tok)
      case prod
      when "@prefix", "@base", "@keywords"
        add_prod_data(:prod, prod)
      when "prefix"
        add_prod_data(:prefix, tok[0..-2])
      when "explicituri"
        add_prod_data(:explicituri, tok[1..-2])
      else
        add_prod_data(prod.to_sym, tok)
      end
    end

    def declarationFinish
      decl = @prod_data.pop
      case decl[:prod]
      when "@prefix"
        uri = process_uri(decl[:explicituri])
        namespace(decl[:prefix], uri)
      when "@base"
        # Base, set or update document URI
        uri = decl[:explicituri]
        @uri = process_uri(uri)
        
        # The empty prefix "" is by default , bound to "#" -- the local namespace of the file.
        # The parser behaves as though there were a
        #   @prefix : <#>.
        # just before the file.
        # This means that <#foo> can be written :foo and using @keywords one can reduce that to foo.
        
        namespace(nil, uri.match(/[\/\#]$/) ? @uri : process_uri("#{uri}#"))
        add_debug("declarationFinish[@base]", "@base=#{@uri}")
      when "@keywords"
        add_debug("declarationFinish[@keywords]", @keywords.inspect)
        # Keywords are handled in tokenizer and maintained in @keywords array
        if (@keywords & N3_KEYWORDS) != @keywords
          error("Undefined keywords used: #{(@keywords - N3_KEYWORDS).to_sentence}") if validate?
        end
        @userkeys = true
      else
        error("declarationFinish: FIXME #{decl.inspect}")
      end
    end
    
    # Document start, instantiate
    def documentStart(prod)
      @formulae.push(bnode)
      @prod_data << {}
    end
    
    def dtlangToken(prod, tok)
      add_prod_data(:langcode, tok) if prod == "langcode"
    end
    
    def existentialStart(prod)
      @prod_data << {}
    end

    def existentialFinish
      pd = @prod_data.pop
      forSome = pd.has_key?(:symbol) ? pd[:symbol] : []
      forSome.each do |term|
        b = bnode
        @existentials[term] = {:formula => @formulae.last, :node => b}
        quantify(@formulae.last, b)
      end
    end
    
    def expressionStart(prod)
      @prod_data << {}
    end
    
    # Process path items, and push on the last object for parent processing
    def expressionFinish
      expression = @prod_data.pop
      
      if expression[:pathitem] && expression[:expression]
        add_prod_data(:expression, process_path(expression))
      elsif expression[:pathitem]
        add_prod_data(:expression, expression[:pathitem])
      else
        error("expressionFinish: FIXME #{expression.inspect}")
      end
    end
    
    def literalStart(prod)
      @prod_data << {}
    end
    
    def literalToken(prod, tok)
      tok = tok[0, 3] == '"""' ? tok[3..-4] : tok[1..-2]
      add_prod_data(:string, tok)
    end
    
    def literalFinish
      lit = @prod_data.pop
      content = RDF::NTriples.unescape(lit[:string])
      language = lit[:langcode]
      datatype = lit[:symbol]
      
      lit = RDF::Literal.new(content, :language => language, :datatype => datatype, :validate => validate?, :canonicalize => canonicalize?)
      add_prod_data(:literal, lit)
    end
    
    def objectStart(prod)
      @prod_data << {}
    end
    
    def objectFinish
      object = @prod_data.pop
      if object[:expression]
        add_prod_data(:object, object[:expression])
      else
        error("objectFinish: FIXME #{object.inspect}")
      end
    end
    
    def pathitemStart(prod)
      @prod_data << {}
    end
    
    def pathitemToken(prod, tok)
      case prod
      when "numericliteral"
        nl = RDF::NTriples.unescape(tok)
        datatype = case nl
        when /e/i then RDF::XSD.double
        when /\./ then RDF::XSD.decimal
        else RDF::XSD.integer
        end
        
        lit = RDF::Literal.new(nl, :datatype => datatype, :validate => validate?, :canonicalize => true)
        add_prod_data(:literal, lit)
      when "quickvariable"
        error("pathitemToken(quickvariable): FIXME #{pathitem.inspect}")
      when "boolean"
        lit = RDF::Literal.new(tok.delete("@"), :datatype => RDF::XSD.boolean, :validate => validate?, :canonicalize => true)
        add_prod_data(:literal, lit)
      when "[", "("
        # Push on state for content of blank node
        @prod_data << {}
      when "]", ")"
        # Construct
        symbol = process_anonnode(@prod_data.pop)
        add_prod_data(:symbol, symbol)
      else
        error("pathitemToken(#{prod}, #{tok}): FIXME")
      end
    end

    def pathitemFinish
      pathitem = @prod_data.pop
      if pathitem[:pathlist]
        error("pathitemFinish(pathlist): FIXME #{pathitem.inspect}")
      elsif pathitem[:propertylist]
        error("pathitemFinish(propertylist): FIXME #{pathitem.inspect}")
      elsif pathitem[:symbol] || pathitem[:literal]
        add_prod_data(:pathitem, pathitem[:symbol] || pathitem[:literal])
      else
        error("pathitemFinish: FIXME #{pathitem.inspect}")
      end
    end
    
    def pathlistStart(prod)
      @prod_data << {:pathlist => []}
    end
    
    def pathlistFinish
      pathlist = @prod_data.pop
      # Flatten propertylist into an array
      expr = @prod_data.last.delete(:expression)
      add_prod_data(:pathlist, expr) if expr
      add_prod_data(:pathlist, pathlist[:pathlist]) if pathlist[:pathlist]
    end
    
    def propertylistStart(prod)
      @prod_data << {}
    end
    
    def propertylistFinish
      propertylist = @prod_data.pop
      # Flatten propertylist into an array
      ary = [propertylist, propertylist.delete(:propertylist)].flatten.compact
      @prod_data.last[:propertylist] = ary
    end
    
    def simpleStatementStart(prod)
      @prod_data << {}
    end
    
    # Completion of Simple Statement, all productions include :subject, and :propertyList
    def simpleStatementFinish
      statement = @prod_data.pop
      
      subject = statement[:subject]
      properties = [statement[:propertylist]].flatten.compact
      properties.each do |p|
        predicate = p[:verb]
        next unless predicate
        add_debug("simpleStatementFinish(pred)", predicate)
        error(%(Illegal statment: "#{predicate}" missing object)) unless p.has_key?(:object)
        objects =[ p[:object]].flatten.compact
        objects.each do |object|
          if p[:invert]
            add_triple("simpleStatementFinish", object, predicate, subject)
          else
            add_triple("simpleStatementFinish", subject, predicate, object)
          end
        end
      end
    end

    def subjectStart(prod)
      @prod_data << {}
    end
    
    def subjectFinish
      subject = @prod_data.pop
      
      if subject[:expression]
        add_prod_data(:subject, subject[:expression])
      else
        error("unknown expression type")
      end
    end
    
    def symbolToken(prod, tok)
      term = case prod
      when 'explicituri'
        process_uri(tok[1..-2])
      when 'qname'
        process_qname(tok)
      else
        error("symbolToken(#{prod}, #{tok}): FIXME #{term.inspect}")
      end
      
      add_prod_data(:symbol, term)
    end

    def universalStart(prod)
      @prod_data << {}
    end

    def universalFinish
      pd = @prod_data.pop
      forAll = pd.has_key?(:symbol) ? pd[:symbol] : []
      forAll.each do |term|
#        v = self.univar('var')
#        @universals[term] = {:formula => @formulae,last, :var => v}
#        quantify(@formulae.last, v)
      end
    end

    def verbStart(prod)
      @prod_data << {}
    end
    
    def verbToken(prod, tok)
      term = case prod
      when '<='
        add_prod_data(:expression, RDF::LOG.implies)
        add_prod_data(:invert, true)
      when '=>'
        add_prod_data(:expression, RDF::LOG.implies)
      when '='
        add_prod_data(:expression, RDF::OWL.sameAs)
      when '@a'
        add_prod_data(:expression, RDF.type)
      when '@has', "@of"
        # Syntactic sugar
      when '@is'
        add_prod_data(:invert, true)
      else
        error("verbToken(#{prod}, #{tok}): FIXME #{term.inspect}")
      end
      
      add_prod_data(:symbol, term)
    end

    def verbFinish
      verb = @prod_data.pop
      if verb[:expression]
        error("Literal may not be used as a predicate") if verb[:expression].is_a?(RDF::Literal)
        add_prod_data(:verb, verb[:expression])
        add_prod_data(:invert, true) if verb[:invert]
      else
        error("verbFinish: FIXME #{verb.inspect}")
      end
    end
    
    private
    
    ###################
    # Utility Functions
    ###################

    # Add values to production data, values aranged as an array
    def add_prod_data(sym, value)
      case @prod_data.last[sym]
      when nil
        @prod_data.last[sym] = value
      when Array
        @prod_data.last[sym] << value
      else
        @prod_data.last[sym] = [@prod_data.last[sym], value]
      end
    end

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
      puts "[#{@lineno},#{@pos}]#{' ' * @productions.length}#{node}: #{message}" if ::RDF::N3::debug?
      @options[:debug] << "[#{@lineno},#{@pos}]#{' ' * @productions.length}#{node}: #{message}" if @options[:debug].is_a?(Array)
    end

    # add a statement, object can be literal or URI or bnode
    #
    # @param [Nokogiri::XML::Node, any] node:: XML Node or string for showing context
    # @param [URI, Node] subject:: the subject of the statement
    # @param [URI] predicate:: the predicate of the statement
    # @param [URI, Node, Literal] object:: the object of the statement
    # @return [Statement]:: Added statement
    # @raise [RDF::ReaderError]:: Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_triple(node, subject, predicate, object)
      statement = RDF::Statement.new(subject, predicate, object)
      add_debug(node, statement.to_s)
      @callback.call(statement)
    end

    def namespace(prefix, uri)
      uri = uri.to_s
      if uri == "#"
        uri = prefix(nil)
      end
      add_debug("namesspace", "'#{prefix}' <#{uri}>")
      prefix(prefix, uri(uri))
    end

    def process_anonnode(anonnode)
      add_debug("process_anonnode", anonnode.inspect)
      bnode = RDF::Node.new
      
      if anonnode[:propertylist]
        properties = anonnode[:propertylist]
        properties.each do |p|
          predicate = p[:verb]
          add_debug("process_anonnode(verb)", predicate.inspect)
          objects = [p[:object]].flatten.compact
          objects.each { |object| add_triple("anonnode", bnode, predicate, object) }
        end
      elsif anonnode[:pathlist]
        objects = [anonnode[:pathlist]].flatten.compact
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

    def process_expression(expression)
      if expression.respond_to?(:pathitem) && expression.respond_to?(:expression)
        add_debug(*expression.info("process_expression(pathitem && expression)"))
        process_path(expression)  # Returns last object in chain
      elsif expression.respond_to?(:uri)
        add_debug(*expression.info("process_expression(uri)"))
        process_uri(expression.uri)
      elsif expression.respond_to?(:localname)
        add_debug(*expression.info("process_expression(localname)"))
        process_qname(expression)
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
          process_qname(barename)
        else
          RDF::Literal.new(barename.delete("@"), :datatype => RDF::XSD.boolean, :validate => validate?, :canonicalize => canonicalize?)
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
          process_qname(barename)
        end
      else
        add_debug(*expression.info("process_expression(else)"))
        process_qname(expression)
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
    def process_path(expression)
      add_debug("process_path", expression.inspect)

      object = process_pathitem(expression[:pathitem])
      
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
    
    def process_uri(uri)
      uri(@uri, RDF::NTriples.unescape(uri))
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

    def process_numeric_literal(object)
      add_debug(*object.info("process_numeric_literal"))

      RDF::Literal.new(RDF::NTriples.unescape(object.text_value), :datatype => RDF::XSD[object.numericliteral], :validate => validate?, :canonicalize => canonicalize?)
    end
    
    def process_qname(tok)
      if tok.include?(":")
        prefix, name = tok.split(":")
      elsif @userkeys
        # If the @keywords directive is given, the keywords given will thereafter be recognized
        # without a "@" prefix, and anything else is a local name in the default namespace.
        prefix, name = "", tok
      elsif %w(true false).include?(tok)
        # The words true and false are boolean literals.
        #
        # They were added to Notation3 in 2006-02 in discussion with the SPARQL language developers, the Data
        # Access Working Group. Note that no existing documents will have used a naked true or false word, without a
        # @keyword statement which would make it clear that they were not to be treated as keywords. Furthermore any
        # old parser encountering true or false naked or in a @keywords
        return RDF::Literal.new(tok, :datatype => RDF::XSD.boolean)
      else
        error("Set user @keywords to use barenames.")
      end

      uri = if prefix(prefix)
        add_debug('process_qname(ns)', "#{prefix(prefix)}, #{name}")
        ns(prefix, name)
      elsif prefix == '_'
        add_debug('process_qname(bnode)', name)
        bnode(name)
      else
        add_debug('process_qname(default_ns)', name)
        namespace(nil, uri("#{@uri}#")) unless prefix(nil)
        ns(nil, name)
      end
      add_debug('process_qname', uri.inspect)
      uri
    end
    
    # Is this an allowable keyword?
    def keyword_check(kw)
      unless (@keywords || %w(a is of has)).include?(kw)
        raise RDF::ReaderError, "unqualified keyword '#{kw}' used without @keyword directive" if validate?
      end
    end
    
    # Create URIs
    def uri(value, append = nil)
      value = RDF::URI.new(value)
      value = value.join(append) if append
      value.validate! if validate? && value.respond_to?(:validate)
      value.canonicalize! if canonicalize?
      value = RDF::URI.intern(value) if intern?
      value
    end
    
    def ns(prefix, suffix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      add_debug("ns", "base: '#{base}', suffix: '#{suffix}'")
      uri(base + suffix.to_s)
    end
  end
end
