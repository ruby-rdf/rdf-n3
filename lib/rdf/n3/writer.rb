require 'rdf/rdfxml/patches/graph_properties'

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
  # @author [Gregg Kellogg](http://kellogg-assoc.com/)
  class Writer < RDF::Writer
    format RDF::N3::Format

    SUBJECT = 0
    VERB = 1
    OBJECT = 2

    attr_accessor :graph, :base_uri

    ##
    # Initializes the Turtle writer instance.
    #
    # Opitons:
    # max_depth:: Maximum depth for recursively defining resources, defaults to 3
    # base_uri:: Base URI of graph, used to shorting URI references
    # default_namespace:: URI to use as default namespace
    #
    # @param  [IO, File]               output
    # @param  [Hash{Symbol => Object}] options
    #   @option options [Integer]       :max_depth      (nil)
    #   @option options [String, #to_s] :base_uri (nil)
    #   @option options [String, #to_s] :lang   (nil)
    #   @option options [Array]         :attributes   (nil)
    #   @option options [String]        :default_namespace
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, options = {}, &block)
      @graph = RDF::Graph.new
      @stream = output
      super
    end

    ##
    # @param  [Graph] graph
    # @return [void]
    def insert_graph(graph)
      @graph = graph
    end

    ##
    # @param  [Statement] statement
    # @return [void]
    def insert_statement(statement)
      @graph << statement
    end

    ##
    # Stores the RDF/XML representation of a triple.
    #
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @return [void]
    # @see    #write_epilogue
    def insert_triple(subject, predicate, object)
      @graph << RDF::Statement.new(subject, predicate, object)
    end

    ##
    # Outputs the N3 representation of all stored triples.
    #
    # @return [void]
    # @see    #write_triple
    def write_epilogue
      @max_depth = @options[:max_depth] || 3
      @base = @options[:base_uri]
      @debug = @options[:debug]
      @default_namespace = @options[:default_namespace]

      self.reset

      add_debug "\nserialize: graph: #{@graph.size}"

      add_namespace("", @default_namespace) if @default_namespace

      preprocess
      start_document

      order_subjects.each do |subject|
        #puts "subj: #{subject.inspect}"
        unless is_done?(subject)
          statement(subject)
        end
      end
    end
    
    protected
    def start_document
      @started = true
      
      write("#{indent}@base <#{@base}> .\n") if @base
      
      add_debug("start_document: #{@namespaces.inspect}")
      @namespaces.keys.sort.each do |prefix|
        write("#{indent}@prefix #{prefix}: <#{@namespaces[prefix]}> .\n")
      end
    end
    
    def end_document; end
    
    # Checks if l is a valid RDF list, i.e. no nodes have other properties.
    def is_valid_list(l)
      props = @graph.properties(l)
      #puts "is_valid_list: #{props.inspect}" if $DEBUG
      return false unless props.has_key?(RDF.first.to_s) || l == RDF.nil
      while l && l != RDF.nil do
        #puts "is_valid_list(length): #{props.length}" if $DEBUG
        return false unless props.has_key?(RDF.first.to_s) && props.has_key?(RDF.rest.to_s)
        n = props[RDF.rest.to_s]
        #puts "is_valid_list(n): #{n.inspect}" if $DEBUG
        return false unless n.is_a?(Array) && n.length == 1
        l = n.first
        props = @graph.properties(l)
      end
      #puts "is_valid_list: valid" if $DEBUG
      true
    end
    
    def do_list(l)
      puts "do_list: #{l.inspect}" if $DEBUG
      position = SUBJECT
      while l do
        p = @graph.properties(l)
        item = p.fetch(RDF.first.to_s, []).first
        if item
          path(item, position)
          subject_done(l)
          position = OBJECT
        end
        l = p.fetch(RDF.rest.to_s, []).first
      end
    end
    
    def p_list(node, position)
      return false if !is_valid_list(node)
      #puts "p_list: #{node.inspect}, #{position}" if $DEBUG

      write(position == SUBJECT ? "(" : " (")
      @depth += 2
      do_list(node)
      @depth -= 2
      write(')')
    end
    
    def p_squared?(node, position)
      node.is_a?(RDF::Node) &&
        !@serialized.has_key?(node) &&
        ref_count(node) <= 1
    end
    
    def p_squared(node, position)
      return false unless p_squared?(node, position)

      #puts "p_squared: #{node.inspect}, #{position}" if $DEBUG
      subject_done(node)
      write(position == SUBJECT ? '[' : ' [')
      @depth += 2
      predicate_list(node)
      @depth -= 2
      write(']')
      
      true
    end
    
    def p_default(node, position)
      #puts "p_default: #{node.inspect}, #{position}" if $DEBUG
      l = (position == SUBJECT ? "" : " ") + label(node)
      write(l)
    end
    
    def path(node, position)
      puts "path: #{node.inspect}, pos: #{position}, []: #{is_valid_list(node)}, p2?: #{p_squared?(node, position)}, rc: #{ref_count(node)}" if $DEBUG
      raise RDF::WriterError, "Cannot serialize node '#{node}'" unless p_list(node, position) || p_squared(node, position) || p_default(node, position)
    end
    
    def verb(node)
      puts "verb: #{node.inspect}" if $DEBUG
      if node == RDF.type
        write(" a")
      else
        path(node, VERB)
      end
    end
    
    def object_list(objects)
      puts "object_list: #{objects.inspect}" if $DEBUG
      return if objects.empty?

      objects.each_with_index do |obj, i|
        write(",\n#{indent(2)}") if i > 0
        path(obj, OBJECT)
      end
    end
    
    def predicate_list(subject)
      properties = @graph.properties(subject)
      prop_list = sort_properties(properties) - [RDF.first.to_s, RDF.rest.to_s]
      puts "predicate_list: #{prop_list.inspect}" if $DEBUG
      return if prop_list.empty?

      prop_list.each_with_index do |prop, i|
        write(";\n#{indent(2)}") if i > 0
        verb(RDF::URI.new(prop))
        object_list(properties[prop])
      end
    end
    
    def s_squared?(subject)
      ref_count(subject) == 0 && subject.is_a?(RDF::Node) && !is_valid_list(subject)
    end
    
    def s_squared(subject)
      return false unless s_squared?(subject)
      
      write("\n#{indent} [")
      @depth += 1
      predicate_list(subject)
      @depth -= 1
      write("] .")
      true
    end
    
    def s_default(subject)
      write("\n#{indent}")
      path(subject, SUBJECT)
      predicate_list(subject)
      write(" .")
      true
    end
    
    def relativize(uri)
      uri = uri.to_s
      @base ? uri.sub(/^#{@base}/, "") : uri
    end

    def statement(subject)
      puts "statement: #{subject.inspect}, s2?: #{s_squared(subject)}" if $DEBUG
      subject_done(subject)
      s_squared(subject) || s_default(subject)
    end
    
    MAX_DEPTH = 10
    INDENT_STRING = " "
    
    def top_classes; [RDF::RDFS.Class]; end
    def predicate_order; [RDF.type, RDF::RDFS.label, RDF::DC.title]; end
    
    def is_done?(subject)
      @serialized.include?(subject)
    end
    
    # Mark a subject as done.
    def subject_done(subject)
      @serialized[subject] = true
    end
    
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
    
    def preprocess
      @graph.each {|statement| preprocess_statement(statement)}
    end
    
    def preprocess_statement(statement)
      #add_debug "preprocess: #{statement.inspect}"
      references = ref_count(statement.object) + 1
      @references[statement.object] = references
      @subjects[statement.subject] = true
      
      # Pre-fetch qnames, to fill namespaces
      get_qname(statement.subject)
      get_qname(statement.predicate)
      get_qname(statement.object)

      @references[statement.predicate] = ref_count(statement.predicate) + 1
    end
    
    # Return the number of times this node has been referenced in the object position
    def ref_count(node)
      @references.fetch(node, 0)
    end

    # Return a QName for the URI, or nil. Adds namespace of QName to defined namespaces
    def get_qname(uri)
      if uri.is_a?(RDF::URI)
        md = uri.to_s.match(/^#{@base}(.*)$/) if @base
        return "<#{md[1]}>" if md

        # Duplicate logic from URI#qname to remember namespace assigned

        if uri.qname
          return ":#{uri.qname.last}" if uri.vocab == @default_namespace
          add_namespace(uri.qname.first, uri.vocab)
          add_debug "get_qname(uri.qname): #{uri.qname.join(':')}"
          return uri.qname.join(":") 
        end
        
        # No vocabulary assigned, find one from cache of created namespace URIs
        @namespaces.each_pair do |prefix, vocab|
          if uri.to_s.index(vocab.to_s) == 0
            uri.vocab = vocab
            local_name = uri.to_s[(vocab.to_s.length)..-1]
            if vocab == @default_namespace
              add_debug "get_qname(ns): :#{local_name}"
              return ":#{local_name}"
            else
              add_debug "get_qname(ns): #{prefix}:#{local_name}"
              return "#{prefix}:#{local_name}"
            end
          end
        end
        
        nil
      end
    end
    
    def label(node)
      get_qname(node) || (node.uri? ? "<#{node}>" : node.to_s)
    end

    def add_namespace(prefix, ns)
      return if @namespaces.has_key?(prefix.to_s)
      add_debug "add_namespace: '#{prefix}', <#{ns}>"
      @namespaces[prefix.to_s] = ns.to_s
    end

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

    # Take a hash from predicate uris to lists of values.
    # Sort the lists of values.  Return a sorted list of properties.
    def sort_properties(properties)
      properties.keys.each do |k|
        properties[k] = properties[k].sort do |a, b|
          a_li = a.is_a?(RDF::URI) && a.qname && a.qname.last =~ /^_\d+$/ ? a.to_i : a.to_s
          b_li = b.is_a?(RDF::URI) && b.qname && b.qname.last =~ /^_\d+$/ ? b.to_i : b.to_s
          
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

    # Add debug event to debug array, if specified
    #
    # @param [String] message::
    def add_debug(message)
      @debug << message if @debug.is_a?(Array)
    end

    # Returns indent string multiplied by the depth
    def indent(modifier = 0)
      INDENT_STRING * (@depth + modifier)
    end

    # Write text
    def write(text)
      @stream.write(text)
    end
  end
end