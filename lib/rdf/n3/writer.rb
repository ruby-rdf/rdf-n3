# coding: utf-8
module RDF::N3
  ##
  # A Turtle serialiser in Ruby
  #
  # Note that the natural interface is to write a whole graph at a time.
  # Writing statements or Triples will create a graph to add them to
  # and then serialize the graph.
  #
  # @example Obtaining a Turtle writer class
  #   RDF::Writer.for(:n3)         #=> RDF::N3::Writer
  #   RDF::Writer.for("etc/test.n3")
  #   RDF::Writer.for("etc/test.ttl")
  #   RDF::Writer.for(file_name:      "etc/test.n3")
  #   RDF::Writer.for(file_name:      "etc/test.ttl")
  #   RDF::Writer.for(file_extension: "n3")
  #   RDF::Writer.for(file_extension: "ttl")
  #   RDF::Writer.for(content_type:   "text/n3")
  #
  # @example Serializing RDF graph into an Turtle file
  #   RDF::N3::Writer.open("etc/test.n3") do |writer|
  #     writer << graph
  #   end
  #
  # @example Serializing RDF statements into an Turtle file
  #   RDF::N3::Writer.open("etc/test.n3") do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF statements into an Turtle string
  #   RDF::N3::Writer.buffer do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # The writer will add prefix definitions, and use them for creating @prefix definitions, and minting QNames
  #
  # @example Creating @base and @prefix definitions in output
  #   RDF::N3::Writer.buffer(base_uri: "http://example.com/", prefixes: {
  #       nil => "http://example.com/ns#",
  #       foaf: "http://xmlns.com/foaf/0.1/"}
  #   ) do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Writer < RDF::Writer
    format RDF::N3::Format
    include RDF::Util::Logger
    QNAME = Meta::REGEXPS[:"http://www.w3.org/2000/10/swap/grammar/n3#qname"]

    # @return [Graph] Graph of statements serialized
    attr_accessor :graph
    # @return [URI] Base URI used for relativizing URIs
    attr_accessor :base_uri

    ##
    # N3 Writer options
    # @see http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Writer#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :max_depth,
          datatype: Integer,
          on: ["--max-depth"],
          description: "Maximum depth for recursively defining resources, defaults to 3.") {|arg| arg.to_i},
        RDF::CLI::Option.new(
          symbol: :default_namespace,
          datatype: RDF::URI,
          on: ["--default-namespace URI", :REQUIRED],
          description: "URI to use as default namespace, same as prefixes.") {|arg| RDF::URI(arg)},
      ]
    end

    ##
    # Initializes the Turtle writer instance.
    #
    # @param  [IO, File] output
    #   the output stream
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Encoding] :encoding     (Encoding::UTF_8)
    #   the encoding to use on the output stream (Ruby 1.9+)
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize literals when serializing
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all writers)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when constructing relative URIs
    # @option options [Integer]  :max_depth      (3)
    #   Maximum depth for recursively defining resources, defaults to 3
    # @option options [Boolean]  :standard_prefixes   (false)
    #   Add standard prefixes to @prefixes, if necessary.
    # @option options [String]   :default_namespace (nil)
    #   URI to use as default namespace, same as prefixes[nil]
    # @option options [Boolean]  :unique_bnodes   (false)
    #   Use unique node identifiers, defaults to using the identifier which the node was originall initialized with (if any).
    # @yield  [writer] `self`
    # @yieldparam  [RDF::Writer] writer
    # @yieldreturn [void]
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, options = {}, &block)
      super do
        @graph = RDF::Graph.new
        @uri_to_qname = {}
        @uri_to_prefix = {}
        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    ##
    # Addes a triple to be serialized
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @return [void]
    # @raise  [NotImplementedError] unless implemented in subclass
    # @abstract
    def write_triple(subject, predicate, object)
      @graph.insert(RDF::Statement(subject, predicate, object))
    end

    ##
    # Outputs the N3 representation of all stored triples.
    #
    # @return [void]
    # @see    #write_triple
    def write_epilogue
      @max_depth = @options[:max_depth] || 3
      @base_uri = RDF::URI(@options[:base_uri])

      self.reset

      log_debug {"\nserialize: graph: #{@graph.size}"}

      preprocess
      start_document

      order_subjects.each do |subject|
        unless is_done?(subject)
          statement(subject)
        end
      end

      super
    end
    
    # Return a QName for the URI, or nil. Adds namespace of QName to defined prefixes
    # @param [RDF::Resource] resource
    # @return [String, nil] value to use to identify URI
    def get_qname(resource)
      case resource
      when RDF::Node
        return options[:unique_bnodes] ? resource.to_unique_base : resource.to_base
      when RDF::URI
        uri = resource.to_s
      else
        return nil
      end

      log_debug {"get_qname(#{resource}), std?}"}
      qname = case
      when @uri_to_qname.has_key?(uri)
        return @uri_to_qname[uri]
      when u = @uri_to_prefix.keys.detect {|u| uri.index(u.to_s) == 0}
        # Use a defined prefix
        prefix = @uri_to_prefix[u]
        prefix(prefix, u) unless u.to_s.empty? # Define for output
        log_debug {"get_qname: add prefix #{prefix.inspect} => #{u}"}
        uri.sub(u.to_s, "#{prefix}:")
      when @options[:standard_prefixes] && vocab = RDF::Vocabulary.each.to_a.detect {|v| uri.index(v.to_uri.to_s) == 0}
        prefix = vocab.__name__.to_s.split('::').last.downcase
        @uri_to_prefix[vocab.to_uri.to_s] = prefix
        prefix(prefix, vocab.to_uri) # Define for output
        log_debug {"get_qname: add standard prefix #{prefix.inspect} => #{vocab.to_uri}"}
        uri.sub(vocab.to_uri.to_s, "#{prefix}:")
      else
        nil
      end
      
      # Make sure qname is a valid qname
      if qname
        md = QNAME.match(qname)
        qname = nil unless md.to_s.length == qname.length
      end

      @uri_to_qname[uri] = qname
    rescue Addressable::URI::InvalidURIError => e
      raise RDF::WriterError, "Invalid URI #{resource.inspect}: #{e.message}"
    end
    
    # Take a hash from predicate uris to lists of values.
    # Sort the lists of values.  Return a sorted list of properties.
    # @param [Hash{String => Array<Resource>}] properties A hash of Property to Resource mappings
    # @return [Array<String>}] Ordered list of properties. Uses predicate_order.
    def sort_properties(properties)
      # Make sorted list of properties
      prop_list = []
      
      predicate_order.each do |prop|
        next unless properties[prop.to_s]
        prop_list << prop.to_s
      end
      
      properties.keys.sort.each do |prop|
        next if prop_list.include?(prop.to_s)
        prop_list << prop.to_s
      end
      
      log_debug {"sort_properties: #{prop_list.join(', ')}"}
      prop_list
    end

    ##
    # Returns the N-Triples representation of a literal.
    #
    # @param  [RDF::Literal, String, #to_s] literal
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_literal(literal, options = {})
      literal = literal.dup.canonicalize! if @options[:canonicalize]
      case literal
      when RDF::Literal
        case literal.datatype
        when RDF::XSD.boolean, RDF::XSD.integer, RDF::XSD.decimal
          literal.to_s
        when RDF::XSD.double
          literal.to_s.sub('E', 'e')  # Favor lower case exponent
        else
          text = quoted(literal.value)
          text << "@#{literal.language}" if literal.has_language?
          text << "^^#{format_uri(literal.datatype)}" if literal.has_datatype?
          text
        end
      else
        quoted(literal.to_s)
      end
    end
    
    ##
    # Returns the Turtle/N3 representation of a URI reference.
    #
    # @param  [RDF::URI] uri
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_uri(uri, options = {})
      md = relativize(uri)
      log_debug {"relativize(#{uri.inspect}) => #{md.inspect}"} if md != uri.to_s
      md != uri.to_s ? "<#{md}>" : (get_qname(uri) || "<#{uri}>")
    end
    
    ##
    # Returns the Turtle/N3 representation of a blank node.
    #
    # @param  [RDF::Node] node
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_node(node, options = {})
      options[:unique_bnodes] ? node.to_unique_base : node.to_base
    end
    
    protected
    # Output @base and @prefix definitions
    def start_document
      @started = true
      
      @output.write("#{indent}@base <#{base_uri}> .\n") unless base_uri.to_s.empty?
      
      log_debug {"start_document: #{prefixes.inspect}"}
      prefixes.keys.sort_by(&:to_s).each do |prefix|
        @output.write("#{indent}@prefix #{prefix}: <#{prefixes[prefix]}> .\n")
      end
    end
    
    # If base_uri is defined, use it to try to make uri relative
    # @param [#to_s] uri
    # @return [String]
    def relativize(uri)
      uri = uri.to_s
      base_uri ? uri.sub(base_uri.to_s, "") : uri
    end

    # Defines rdf:type of subjects to be emitted at the beginning of the graph. Defaults to rdfs:Class
    # @return [Array<URI>]
    def top_classes; [RDF::RDFS.Class]; end

    # Defines order of predicates to to emit at begninning of a resource description. Defaults to
    # [rdf:type, rdfs:label, dc:title]
    # @return [Array<URI>]
    def predicate_order; [RDF.type, RDF::RDFS.label, RDF::URI("http://purl.org/dc/terms/title")]; end
    
    # Order subjects for output. Override this to output subjects in another order.
    #
    # Uses #top_classes and #base_uri.
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      seen = {}
      subjects = []
      
      # Start with base_uri
      if base_uri && @subjects.keys.include?(base_uri)
        subjects << base_uri
        seen[base_uri] = true
      end
      log_debug {"subjects1: #{subjects.inspect}"}
      
      # Add distinguished classes
      top_classes.each do |class_uri|
        graph.query(predicate: RDF.type, object: class_uri).map {|st| st.subject}.sort.uniq.each do |subject|
          log_debug {"order_subjects: #{subject.inspect}"}
          subjects << subject
          seen[subject] = true
        end
      end
      log_debug {"subjects2: #{subjects.inspect}"}
      
      # Sort subjects by resources over bnodes, ref_counts and the subject URI itself
      recursable = @subjects.keys.
        select {|s| !seen.include?(s)}.
        map {|r| [r.node? ? 1 : 0, ref_count(r), r]}.
        sort
      
      log_debug {"subjects3: #{subjects.inspect}"}
      subjects += recursable.map{|r| r.last}
      log_debug {"subjects4: #{subjects.inspect}"}
      subjects
    end
    
    # Perform any preprocessing of statements required
    def preprocess
      # Load defined prefixes
      (@options[:prefixes] || {}).each_pair do |k, v|
        @uri_to_prefix[v.to_s] = k
      end
      @options[:prefixes] = {}  # Will define actual used when matched

      prefix(nil, @options[:default_namespace]) if @options[:default_namespace]

      @graph.each {|statement| preprocess_statement(statement)}
    end
    
    # Perform any statement preprocessing required. This is used to perform reference counts and determine required
    # prefixes.
    # @param [Statement] statement
    def preprocess_statement(statement)
      #log_debug {"preprocess: #{statement.inspect}"}
      references = ref_count(statement.object) + 1
      @references[statement.object] = references
      @subjects[statement.subject] = true
      
      # Pre-fetch qnames, to fill prefixes
      get_qname(statement.subject)
      get_qname(statement.predicate)
      get_qname(statement.object)
      get_qname(statement.object.datatype) if statement.object.literal? && statement.object.datatype

      @references[statement.predicate] = ref_count(statement.predicate) + 1
    end
    
    # Return the number of times this node has been referenced in the object position
    # @return [Integer]
    def ref_count(node)
      @references.fetch(node, 0)
    end

    # Returns indent string multiplied by the depth
    # @param [Integer] modifier Increase depth by specified amount
    # @return [String] A number of spaces, depending on current depth
    def indent(modifier = 0)
      " " * (@depth + modifier)
    end

    # Reset internal helper instance variables
    def reset
      @depth = 0
      @lists = {}
      @namespaces = {}
      @references = {}
      @serialized = {}
      @subjects = {}
      @shortNames = {}
      @started = false
    end

    ##
    # Use single- or multi-line quotes. If literal contains \t, \n, or \r, use a multiline quote,
    # otherwise, use a single-line
    # @param  [String] string
    # @return [String]
    def quoted(string)
      if string.to_s.match(/[\t\n\r]/)
        string = string.gsub('\\', '\\\\').gsub('"""', '\\"""')
        %("""#{string}""")
      else
        "\"#{escaped(string)}\""
      end
    end

    private
    
    # Checks if l is a valid RDF list, i.e. no nodes have other properties.
    def is_valid_list(l)
      #log_debug {"is_valid_list: #{l.inspect}"}
      return (l.node? && RDF::List.new(subject: l, graph: @graph).valid?) || l == RDF.nil
    end
    
    def do_list(l)
      list = RDF::List.new(subject: l, graph: @graph)
      log_debug {"do_list: #{list.inspect}"}
      position = :subject
      list.each_statement do |st|
        next unless st.predicate == RDF.first
        log_debug {" list this: #{st.subject} first: #{st.object}[#{position}]"}
        path(st.object, position)
        subject_done(st.subject)
        position = :object
      end
    end
    
    def p_list(node, position)
      return false if !is_valid_list(node)
      #log_debug {"p_list: #{node.inspect}, #{position}"}

      @output.write(position == :subject ? "(" : " (")
      @depth += 2
      do_list(node)
      @depth -= 2
      @output.write(')')
    end
    
    def p_squared?(node, position)
      node.node? &&
        !@serialized.has_key?(node) &&
        ref_count(node) <= 1
    end
    
    def p_squared(node, position)
      return false unless p_squared?(node, position)

      #log_debug {"p_squared: #{node.inspect}, #{position}"}
      subject_done(node)
      @output.write(position == :subject ? '[' : ' [')
      @depth += 2
      predicate_list(node)
      @depth -= 2
      @output.write(']')
      
      true
    end
    
    def p_default(node, position)
      #log_debug {"p_default: #{node.inspect}, #{position}"}
      l = (position == :subject ? "" : " ") + format_term(node, options)
      @output.write(l)
    end
    
    def path(node, position)
      log_debug do
        "path: #{node.inspect}, " +
        "pos: #{position}, " +
        "[]: #{is_valid_list(node)}, " +
        "p2?: #{p_squared?(node, position)}, " +
        "rc: #{ref_count(node)}"
      end
      raise RDF::WriterError, "Cannot serialize node '#{node}'" unless p_list(node, position) || p_squared(node, position) || p_default(node, position)
    end
    
    def verb(node)
      log_debug {"verb: #{node.inspect}"}
      if node == RDF.type
        @output.write(" a")
      else
        path(node, :predicate)
      end
    end
    
    def object_list(objects)
      log_debug {"object_list: #{objects.inspect}"}
      return if objects.empty?

      objects.each_with_index do |obj, i|
        @output.write(",\n#{indent(4)}") if i > 0
        path(obj, :object)
      end
    end
    
    def predicate_list(subject)
      properties = {}
      @graph.query(subject: subject) do |st|
        properties[st.predicate.to_s] ||= []
        properties[st.predicate.to_s] << st.object
      end

      prop_list = sort_properties(properties) - [RDF.first.to_s, RDF.rest.to_s]
      log_debug {"predicate_list: #{prop_list.inspect}"}
      return if prop_list.empty?

      prop_list.each_with_index do |prop, i|
        begin
          @output.write(";\n#{indent(2)}") if i > 0
          verb(prop[0, 2] == "_:" ? RDF::Node.intern(prop.split(':').last) : RDF::URI.intern(prop))
          object_list(properties[prop])
        rescue Addressable::URI::InvalidURIError => e
          log_debug {"Predicate #{prop.inspect} is an invalid URI: #{e.message}"}
        end
      end
    end
    
    def s_squared?(subject)
      ref_count(subject) == 0 && subject.node? && !is_valid_list(subject)
    end
    
    def s_squared(subject)
      return false unless s_squared?(subject)
      
      log_debug {"s_squared: #{subject.inspect}"}
      @output.write("\n#{indent} [")
      @depth += 1
      predicate_list(subject)
      @depth -= 1
      @output.write("] .")
      true
    end
    
    def s_default(subject)
      @output.write("\n#{indent}")
      path(subject, :subject)
      predicate_list(subject)
      @output.write(" .")
      true
    end
    
    def statement(subject)
      log_debug {"statement: #{subject.inspect}, s2?: #{s_squared?(subject)}"}
      subject_done(subject)
      s_squared(subject) || s_default(subject)
      @output.write("\n")
    end
    
    def is_done?(subject)
      @serialized.include?(subject)
    end
    
    # Mark a subject as done.
    def subject_done(subject)
      @serialized[subject] = true
    end
  end
end
