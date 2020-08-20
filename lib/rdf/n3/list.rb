module RDF::N3
  ##
  # Sub-class of RDF::List which uses a native representation of values and allows recursive lists.
  #
  # Also serves as the vocabulary URI for expanding other methods
  class List < RDF::List
    # Allow a list to be treated as a term in a statement.
    include ::RDF::Term

    URI = RDF::URI("http://www.w3.org/2000/10/swap/list#")

    # Returns a vocubulary term
    def self.method_missing(property, *args, &block)
      property = RDF::Vocabulary.camelize(property.to_s)
      if args.empty? && !to_s.empty?
        RDF::Vocabulary::Term.intern("#{URI}#{property}", attributes: {})
      else
        super
      end
    end

    ##
    # Returns the base URI for this vocabulary.
    #
    # @return [URI]
    def self.to_uri
      URI
    end

    ##
    # Attempts to create an RDF::N3::List from subject, or returns the node as is, if unable.
    #
    # @param [RDF::Resource] subject
    # @return [RDF::List, RDF::Resource] returns either the original resource, or a list based on that resource
    def self.try_list(subject, graph)
      return subject unless subject.node? || subject.uri? && subject == RDF.nil
      ln = RDF::List.new(subject: subject, graph: graph)
      return subject unless ln.valid?

      # Return a new list, outside of this queryable, with any embedded lists also expanded
      values = ln.to_a.map {|li| try_list(li, graph)}
      RDF::N3::List.new(subject: subject, graph: graph, values: values)
    end

    ##
    # Initializes a newly-constructed list.
    #
    # Instantiates a new list based at `subject`, which **must** be an RDF::Node. List may be initialized using passed `values`.
    #
    # @example add constructed list to existing graph
    #     l = RDF::N3::List(values: (1, 2, 3))
    #     g = RDF::Graph.new << l
    #     g.count # => l.count
    #
    # If values is not provided, but subject and graph are, then will attempt to recursively represent lists.
    #
    # @param  [RDF::Resource]         subject (RDF.nil)
    #   Subject should be an {RDF::Node}, not a {RDF::URI}. A list with an IRI head will not validate, but is commonly used to detect if a list is valid.
    # @param  [RDF::Graph]        graph (RDF::Graph.new)
    # @param  [Array<RDF::Term>]  values
    #   Any values which are not terms are coerced to `RDF::Literal`.
    # @yield  [list]
    # @yieldparam [RDF::List] list
    def initialize(subject: nil, graph: nil, values: nil, &block)
      @subject = subject || (Array(values).empty? ? RDF.nil : RDF::Node.new)
      @graph = graph
      @valid = true

      @values = case
      when values
        values
      when subject && graph
        ln = RDF::List.new(subject: subject, graph: graph)
        @valid = ln.valid?
        ln.to_a.map {|li| self.class.try_list(li, graph)}
      else
        []
      end
    end

    ##
    # Lists are valid, unless established via RDF::List, in which case they are only valid if the RDF::List is valid.
    #
    # @return [Boolean]
    def valid?; @valid; end

    ##
    # @see RDF::Value#==
    def ==(other)
      case other
      when Array, RDF::List then to_a == other.to_a
      else
        false
      end
    end

    ##
    # Element Assignment — Sets the element at `index`, or replaces a subarray from the `start` index for `length` elements, or replaces a subarray specified by the `range` of indices.
    #
    # @overload []=(index, term)
    #   Replaces the element at `index` with `term`.
    #   @param [Integer] index
    #   @param [RDF::Term] term
    #     A non-RDF::Term is coerced to a Literal.
    #   @return [RDF::Term]
    #   @raise [IndexError]
    #
    # @overload []=(start, length, value)
    #   Replaces a subarray from the `start` index for `length` elements with `value`. Value is a {RDF::Term}, Array of {RDF::Term}, or {RDF::List}.
    #   @param [Integer] start
    #   @param [Integer] length
    #   @param [RDF::Term, Array<RDF::Term>, RDF::List] value
    #     A non-RDF::Term is coerced to a Literal.
    #   @return [RDF::Term, RDF::List]
    #   @raise [IndexError]
    #
    # @overload []=(range, value)
    #   Replaces a subarray from the `start` index for `length` elements with `value`. Value is a {RDF::Term}, Array of {RDF::Term}, or {RDF::List}.
    #   @param [Range] range
    #   @param [RDF::Term, Array<RDF::Term>, RDF::List] value
    #     A non-RDF::Term is coerced to a Literal.
    #   @return [RDF::Term, RDF::List]
    #   @raise [IndexError]
    def []=(*args)
      value = case args.last
      when Array then args.last
      when RDF::List then args.last.to_a
      else [args.last]
      end

      case args.length
      when 3
        start, length = args[0], args[1]
        @value[start, length] = value
        case args.first
        when Integer
          raise ArgumentError, "Index form of []= takes a single term" if args.last.is_a?(Array)
          @value[args.first] = case args.last
          when RDF::N3::List then args.last
          when RDF::List then RDF::N3::List.new(values: args.last.to_a)
          when Array then RDF::N3::List.new(values: args.last.to_a)
          else args.last
          end
        when Range
          @value[args.first] = value
        else
          raise ArgumentError, "Index form of must use an integer or range"
        end
      else
        raise ArgumentError, "List []= takes one or two index values"
      end
    end

    ##
    # Appends an element to the head of this list. Existing references are not updated, as the list subject changes as a side-effect.
    #
    # @example
    #   RDF::List[].unshift(1).unshift(2).unshift(3) #=> RDF::List[3, 2, 1]
    #
    # @param  [RDF::Term, Array<RDF::Term>, RDF::List] value
    #   A non-RDF::Term is coerced to a Literal
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-unshift
    #
    def unshift(value)
      value = normalize_value(value)
      @values.unshift(value)
      @subject = nil

      return self
    end

    ##
    # Removes and returns the element at the head of this list.
    #
    # @example
    #   RDF::List[1,2,3].shift              #=> 1
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-shift
    def shift
      return nil if empty?
      @subject = nil
      @values.shift
    end

    ##
    # Empties this list
    #
    # @example
    #   RDF::List[1, 2, 2, 3].clear    #=> RDF::List[]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-clear
    def clear
      @values.clear
      @subject = nil
      self
    end

    ##
    # Appends an element to the tail of this list.
    #
    # @example
    #   RDF::List[] << 1 << 2 << 3              #=> RDF::List[1, 2, 3]
    #
    # @param  [RDF::Term] value
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-3C-3C
    def <<(value)
      value = normalize_value(value)
      @subject = nil
      @values << value
      self
    end

    ##
    # Returns `true` if this list is empty.
    #
    # @example
    #   RDF::List[].empty?                      #=> true
    #   RDF::List[1, 2, 3].empty?               #=> false
    #
    # @return [Boolean]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-empty-3F
    def empty?
      @values.empty?
    end

    ##
    # Returns the length of this list.
    #
    # @example
    #   RDF::List[].length                      #=> 0
    #   RDF::List[1, 2, 3].length               #=> 3
    #
    # @return [Integer]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-length
    def length
      @values.length
    end

    ##
    # Returns the index of the first element equal to `value`, or `nil` if
    # no match was found.
    #
    # @example
    #   RDF::List['a', 'b', 'c'].index('a')     #=> 0
    #   RDF::List['a', 'b', 'c'].index('d')     #=> nil
    #
    # @param  [RDF::Term] value
    # @return [Integer]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-index
    def index(value)
      @values.index(value)
    end

    ##
    # Returns element at `index` with default.
    #
    # @example
    #   RDF::List[1, 2, 3].fetch(0)             #=> RDF::Literal(1)
    #   RDF::List[1, 2, 3].fetch(4)             #=> IndexError
    #   RDF::List[1, 2, 3].fetch(4, nil)        #=> nil
    #   RDF::List[1, 2, 3].fetch(4) { |n| n*n } #=> 16
    #
    # @return [RDF::Term, nil]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000420
    def fetch(*args, &block)
      @values.fetch(*args, default)
    end

    ##
    # Returns the element at `index`.
    #
    # @example
    #   RDF::List[1, 2, 3].at(0)                #=> 1
    #   RDF::List[1, 2, 3].at(4)                #=> nil
    #
    # @return [RDF::Term, nil]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-at
    def at(index)
      @values.at(index)
    end

    ##
    # Returns the first element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].first               #=> RDF::Literal(1)
    #
    # @return [RDF::Term]
    def first
      @values.first
    end

    ##
    # Returns the last element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].last                 #=> RDF::Literal(10)
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-last
    def last
      @values.last
    end

    ##
    # Returns a list containing all but the first element of this list.
    #
    # @example
    #   RDF::List[1, 2, 3].rest                 #=> RDF::List[2, 3]
    #
    # @return [RDF::List]
    def rest
      self.class.new(values: values[1..-1])
    end

    ##
    # Returns a list containing the last element of this list.
    #
    # @example
    #   RDF::List[1, 2, 3].tail                 #=> RDF::List[3]
    #
    # @return [RDF::List]
    def tail
      self.class.new(values: values[-1..-1])
    end

    ##
    # Yields each element in this list.
    #
    # @example
    #   RDF::List[1, 2, 3].each do |value|
    #     puts value.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    http://ruby-doc.org/core-1.9/classes/Enumerable.html
    def each(&block)
      return to_enum unless block_given?

      @values.each(&block)
    end

    ##
    # Yields each statement constituting this list. Uses actual statements if a graph was set, otherwise, the saved values.
    #
    # This will recursively get statements for sub-lists as well.
    #
    # @example
    #   RDF::List[1, 2, 3].each_statement do |statement|
    #     puts statement.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    RDF::Enumerable#each_statement
    def each_statement(&block)
      return enum_statement unless block_given?

      if graph
        RDF::List.new(subject: subject, graph: graph).each_statement(&block)
      elsif @values.length > 0
        # Create a subject for each entry based on the subject bnode
        subjects = (0..(@values.count-1)).map {|ndx| ndx > 0 ? RDF::Node.intern("#{subject.id}_#{ndx}") : subject}
        *values, last = @values
        while !values.empty?
          subj = subjects.shift
          block.call(RDF::Statement(subj, RDF.first, values.shift))
          block.call(RDF::Statement(subj, RDF.rest, subjects.first))
        end
        subj = subjects.shift
        block.call(RDF::Statement(subj, RDF.first, last))
        block.call(RDF::Statement(subj, RDF.rest, RDF.nil))
      end

      # If a graph was used, also get statements from sub-lists
      @values.select(&:list?).each {|li| li.each_statement(&block)} if graph
    end

    ##
    # Yields each subject term constituting this list along with sub-lists.
    #
    # @example
    #   RDF::List[1, 2, 3].each_subject do |subject|
    #     puts subject.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    RDF::Enumerable#each
    def each_subject(&block)
      return enum_subject unless block_given?

      each_statement {|st| block.call(st.subject) if st.predicate == RDF.rest}
    end

    ##
    # Returns the elements in this list as an array.
    #
    # @example
    #   RDF::List[].to_a                        #=> []
    #   RDF::List[1, 2, 3].to_a                 #=> [RDF::Literal(1), RDF::Literal(2), RDF::Literal(3)]
    #
    # @return [Array]
    def to_a
      @values
    end
  end
end
