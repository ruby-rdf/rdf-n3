require 'rdf/n3/patches/graph_properties'

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
  #   RDF::Writer.for(:file_name      => "etc/test.n3")
  #   RDF::Writer.for(:file_name      => "etc/test.ttl")
  #   RDF::Writer.for(:file_extension => "n3")
  #   RDF::Writer.for(:file_extension => "ttl")
  #   RDF::Writer.for(:content_type   => "text/n3")
  #   RDF::Writer.for(:content_type   => "text/turtle")
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
  #   RDF::N3::Writer.buffer(:base_uri => "http://example.com/", :prefixes => {
  #       nil => "http://example.com/ns#",
  #       :foaf => "http://xmlns.com/foaf/0.1/"}
  #   ) do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @author [Gregg Kellogg](http://kellogg-assoc.com/)
  class Writer < RDF::Writer
    format RDF::N3::Format

    # @return [Graph] Graph of statements serialized
    attr_accessor :graph
    # @return [URI] Base URI used for relativizing URIs
    attr_accessor :base_uri
    
    # FIXME: temporary patch until fixed in RDF.rb
    # Allow for nil prefix mapping
    def prefix(name, uri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      uri.nil? ? prefixes[name] : prefixes[name] = (uri.respond_to?(:to_sym) ? uri.to_sym : uri.to_s.to_sym)
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
    # @yield  [writer] `self`
    # @yieldparam  [RDF::Writer] writer
    # @yieldreturn [void]
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, options = {}, &block)
      super do
        @graph = RDF::Graph.new
        @uri_to_qname = {}
        prefix(nil, @options[:default_namespace]) if @options[:default_namespace]
        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    ##
    # Write whole graph
    #
    # @param  [Graph] graph
    # @return [void]
    def write_graph(graph)
      @graph = graph
    end

    ##
    # Addes a statement to be serialized
    # @param  [RDF::Statement] statement
    # @return [void]
    def write_statement(statement)
      @graph.insert(statement)
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
      @graph.insert(Statement.new(subject, predicate, object))
    end

    ##
    # Outputs the N3 representation of all stored triples.
    #
    # @return [void]
    # @see    #write_triple
    def write_epilogue
      @max_depth = @options[:max_depth] || 3
      @base_uri = @options[:base_uri]
      @debug = @options[:debug]

      self.reset

      add_debug "\nserialize: graph: #{@graph.size}"

      preprocess
      start_document

      order_subjects.each do |subject|
        #puts "subj: #{subject.inspect}"
        unless is_done?(subject)
          statement(subject)
        end
      end
    end
    
    # Return a QName for the URI, or nil. Adds namespace of QName to defined prefixes
    # @param [URI,#to_s] uri
    # @return [Array<Symbol,Symbol>, nil] Prefix, Suffix pair or nil, if none found
    def get_qname(uri)
      uri = RDF::URI.intern(uri.to_s) unless uri.is_a?(URI)

      unless @uri_to_qname.has_key?(uri)
        # Find in defined prefixes
        prefixes.each_pair do |prefix, vocab|
          if uri.to_s.index(vocab.to_s) == 0
            local_name = uri.to_s[(vocab.to_s.length)..-1]
            add_debug "get_qname(ns): #{prefix}:#{local_name}"
            return @uri_to_qname[uri] = [prefix, local_name.to_sym]
          end
        end
        
        # Use a default vocabulary
        if @options[:standard_prefixes] && vocab = RDF::Vocabulary.detect {|v| uri.to_s.index(v.to_uri.to_s) == 0}
          prefix = vocab.__name__.to_s.split('::').last.downcase
          prefixes[prefix.to_sym] = vocab.to_uri
          suffix = uri.to_s[vocab.to_uri.to_s.size..-1]
          return @uri_to_qname[uri] = [prefix.to_sym, suffix.empty? ? nil : suffix.to_sym] if prefix && suffix
        end
        
        @uri_to_qname[uri] = nil
      end
      
      @uri_to_qname[uri]
    rescue Addressable::URI::InvalidURIError
       @uri_to_qname[uri] = nil
    end
    
    # Take a hash from predicate uris to lists of values.
    # Sort the lists of values.  Return a sorted list of properties.
    # @param [Hash{String => Array<Resource>}] properties A hash of Property to Resource mappings
    # @return [Array<String>}] Ordered list of properties. Uses predicate_order.
    def sort_properties(properties)
      properties.keys.each do |k|
        properties[k] = properties[k].sort do |a, b|
          a_li = a.is_a?(RDF::URI) && get_qname(a) && get_qname(a).last.to_s =~ /^_\d+$/ ? a.to_i : a.to_s
          b_li = b.is_a?(RDF::URI) && get_qname(b) && get_qname(b).last.to_s =~ /^_\d+$/ ? b.to_i : b.to_s
          
          a_li <=> b_li
        end
      end
      
      # Make sorted list of properties
      prop_list = []
      
      predicate_order.each do |prop|
        next unless properties[prop]
        prop_list << prop.to_s
      end
      
      properties.keys.sort.each do |prop|
        next if prop_list.include?(prop.to_s)
        prop_list << prop.to_s
      end
      
      add_debug "sort_properties: #{prop_list.to_sentence}"
      prop_list
    end

    ##
    # Returns the N-Triples representation of a literal.
    #
    # @param  [RDF::Literal, String, #to_s] literal
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_literal(literal, options = {})
      case literal
        when RDF::Literal
          text = quoted(literal.value)
          text << "@#{literal.language}" if literal.has_language?
          text << "^^#{format_uri(literal.datatype)}" if literal.has_datatype?
          text
        else
          quoted(literal.to_s)
      end
    end
    
    ##
    # Returns the Turtle/N3 representation of a URI reference.
    #
    # @param  [RDF::URI] literal
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_uri(uri, options = {})
      md = relativize(uri)
      if md && md != uri.to_s
        "<%s>" % md
      elsif qname = get_qname(uri)
        qname.map(&:to_s).join(":")
      else
        "<%s>" % uri_for(uri)
      end
    end
    
    ##
    # Returns the Turtle/N3 representation of a blank node.
    #
    # @param  [RDF::Node] node
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_node(node, options = {})
      "_:%s" % node.id
    end
    
    protected
    # Output @base and @prefix definitions
    def start_document
      @started = true
      
      @output.write("#{indent}@base <#{@base_uri}> .\n") if @base_uri
      
      add_debug("start_document: #{prefixes.inspect}")
      prefixes.keys.sort_by(&:to_s).each do |prefix|
        @output.write("#{indent}@prefix #{prefix}: <#{prefixes[prefix]}> .\n")
      end
    end
    
    # If @base_uri is defined, use it to try to make uri relative
    # @param [#to_s] uri
    # @return [String]
    def relativize(uri)
      uri = uri.to_s
      @base_uri ? uri.sub(@base_uri.to_s, "") : uri
    end

    # Defines rdf:type of subjects to be emitted at the beginning of the graph. Defaults to rdfs:Class
    # @return [Array<URI>]
    def top_classes; [RDF::RDFS.Class]; end

    # Defines order of predicates to to emit at begninning of a resource description. Defaults to
    # [rdf:type, rdfs:label, dc:title]
    # @return [Array<URI>]
    def predicate_order; [RDF.type, RDF::RDFS.label, RDF::DC.title]; end
    
    # Order subjects for output. Override this to output subjects in another order.
    #
    # Uses top_classes
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      seen = {}
      subjects = []
      
      top_classes.each do |class_uri|
        graph.query(:predicate => RDF.type, :object => class_uri).map {|st| st.subject}.sort.uniq.each do |subject|
          #add_debug "order_subjects: #{subject.inspect}"
          subjects << subject
          seen[subject] = @top_levels[subject] = true
        end
      end
      
      # Sort subjects by resources over bnodes, ref_counts and the subject URI itself
      recursable = @subjects.keys.
        select {|s| !seen.include?(s)}.
        map {|r| [r.is_a?(RDF::Node) ? 1 : 0, ref_count(r), r]}.
        sort
      
      subjects += recursable.map{|r| r.last}
    end
    
    # Perform any preprocessing of statements required
    def preprocess
      @graph.each {|statement| preprocess_statement(statement)}
    end
    
    # Perform any statement preprocessing required. This is used to perform reference counts and determine required
    # prefixes.
    # @param [Statement] statement
    def preprocess_statement(statement)
      #add_debug "preprocess: #{statement.inspect}"
      references = ref_count(statement.object) + 1
      @references[statement.object] = references
      @subjects[statement.subject] = true
      
      # Pre-fetch qnames, to fill prefixes
      get_qname(statement.subject)
      get_qname(statement.predicate)
      get_qname(statement.object)

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
      @top_levels = {}
      @shortNames = {}
      @started = false
    end

    private
    
    # Add debug event to debug array, if specified
    #
    # @param [String] message::
    def add_debug(message)
      STDERR.puts message if ::RDF::N3::debug?
      @debug << message if @debug.is_a?(Array)
    end

    # Checks if l is a valid RDF list, i.e. no nodes have other properties.
    def is_valid_list(l)
      props = @graph.properties(l)
      #puts "is_valid_list: #{props.inspect}" if ::RDF::N3::debug?
      return false unless props.has_key?(RDF.first.to_s) || l == RDF.nil
      while l && l != RDF.nil do
        #puts "is_valid_list(length): #{props.length}" if ::RDF::N3::debug?
        return false unless props.has_key?(RDF.first.to_s) && props.has_key?(RDF.rest.to_s)
        n = props[RDF.rest.to_s]
        #puts "is_valid_list(n): #{n.inspect}" if ::RDF::N3::debug?
        return false unless n.is_a?(Array) && n.length == 1
        l = n.first
        props = @graph.properties(l)
      end
      #puts "is_valid_list: valid" if ::RDF::N3::debug?
      true
    end
    
    def do_list(l)
      puts "do_list: #{l.inspect}" if ::RDF::N3::debug?
      position = :subject
      while l do
        p = @graph.properties(l)
        item = p.fetch(RDF.first.to_s, []).first
        if item
          path(item, position)
          subject_done(l)
          position = :object
        end
        l = p.fetch(RDF.rest.to_s, []).first
      end
    end
    
    def p_list(node, position)
      return false if !is_valid_list(node)
      #puts "p_list: #{node.inspect}, #{position}" if ::RDF::N3::debug?

      @output.write(position == :subject ? "(" : " (")
      @depth += 2
      do_list(node)
      @depth -= 2
      @output.write(')')
    end
    
    def p_squared?(node, position)
      node.is_a?(RDF::Node) &&
        !@serialized.has_key?(node) &&
        ref_count(node) <= 1
    end
    
    def p_squared(node, position)
      return false unless p_squared?(node, position)

      #puts "p_squared: #{node.inspect}, #{position}" if ::RDF::N3::debug?
      subject_done(node)
      @output.write(position == :subject ? '[' : ' [')
      @depth += 2
      predicate_list(node)
      @depth -= 2
      @output.write(']')
      
      true
    end
    
    def p_default(node, position)
      #puts "p_default: #{node.inspect}, #{position}" if ::RDF::N3::debug?
      l = (position == :subject ? "" : " ") + format_value(node)
      @output.write(l)
    end
    
    def path(node, position)
      puts "path: #{node.inspect}, pos: #{position}, []: #{is_valid_list(node)}, p2?: #{p_squared?(node, position)}, rc: #{ref_count(node)}" if ::RDF::N3::debug?
      raise RDF::WriterError, "Cannot serialize node '#{node}'" unless p_list(node, position) || p_squared(node, position) || p_default(node, position)
    end
    
    def verb(node)
      puts "verb: #{node.inspect}" if ::RDF::N3::debug?
      if node == RDF.type
        @output.write(" a")
      else
        path(node, :predicate)
      end
    end
    
    def object_list(objects)
      puts "object_list: #{objects.inspect}" if ::RDF::N3::debug?
      return if objects.empty?

      objects.each_with_index do |obj, i|
        @output.write(",\n#{indent(2)}") if i > 0
        path(obj, :object)
      end
    end
    
    def predicate_list(subject)
      properties = @graph.properties(subject)
      prop_list = sort_properties(properties) - [RDF.first.to_s, RDF.rest.to_s]
      puts "predicate_list: #{prop_list.inspect}" if ::RDF::N3::debug?
      return if prop_list.empty?

      prop_list.each_with_index do |prop, i|
        @output.write(";\n#{indent(2)}") if i > 0
        verb(RDF::URI.intern(prop))
        object_list(properties[prop])
      end
    end
    
    def s_squared?(subject)
      ref_count(subject) == 0 && subject.is_a?(RDF::Node) && !is_valid_list(subject)
    end
    
    def s_squared(subject)
      return false unless s_squared?(subject)
      
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
      puts "statement: #{subject.inspect}, s2?: #{s_squared(subject)}" if ::RDF::N3::debug?
      subject_done(subject)
      s_squared(subject) || s_default(subject)
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
