# Refinements on core RDF class behavior
# @see ::RDF::Statement#valid?
# @see ::RDF::Statement#invalid?
# @see ::RDF::Statement#validate!
# @see ::RDF::Query::Pattern#valid?
module RDF::N3::Refinements
  # @!parse
  #   # Refinements on RDF::Statement
  #   class ::RDF::Statement
  #     # Refines `valid?` to allow literal subjects and BNode predicates.
  #     # @return [Boolean]
  #     def valid?; end
  #
  #     # Refines `invalid?` to allow literal subjects and BNode predicates.
  #     # @return [Boolean]
  #     def invalid?; end
  #
  #     # Refines `validate!` to allow literal subjects and BNode predicates.
  #     # @return [RDF::Value] `self`
  #     # @raise  [ArgumentError] if the value is invalid
  #     def validate!; end
  #   end
  refine ::RDF::Statement do
    ##
    # Override `valid?` terms as subjects and resources as predicates.
    #
    # @return [Boolean]
    def valid?
      has_subject?    && subject.term? && subject.valid? &&
      has_predicate?  && predicate.term? && predicate.valid? &&
      has_object?     && object.term? && object.valid? &&
      (has_graph?      ? (graph_name.resource? && graph_name.valid?) : true)
    end

    ##
    # @return [Boolean]
    def invalid?
      !valid?
    end

    ##
    # Default validate! implementation, overridden in concrete classes
    # @return [RDF::Value] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      raise ArgumentError, "#{self.inspect} is not valid" if invalid?
      self
    end
    alias_method :validate, :validate!
  end

  # @!parse
  #   # Refinements on RDF::Query::Pattern
  #   class ::RDF::Query::Pattern
  #     # Refines `valid?` to allow literal subjects and BNode predicates.
  #     # @return [Boolean]
  #     def valid?; end
  #   end
  refine ::RDF::Query::Pattern do
    ##
    # Is this pattern composed only of valid components?
    #
    # @return [Boolean] `true` or `false`
    def valid?
      (has_subject?   ? (subject.term? || subject.variable?) && subject.valid? : true) && 
      (has_predicate? ? (predicate.resource? || predicate.variable?) && predicate.valid? : true) &&
      (has_object?    ? (object.term? || object.variable?) && object.valid? : true) &&
      (has_graph?     ? (graph_name.resource? || graph_name.variable?) && graph_name.valid? : true)
    rescue NoMethodError
      false
    end
  end

  refine ::RDF::List do
    # Allow a list to be treated as a term in a statement.
    include ::RDF::Term

    ##
    # Refine each_statement to recursively emit statements from embedded lists.
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

      each_subject do |subject|
        graph.query({subject: subject}) do |statement|
          if statement.object.list?
            block.call(RDF::Statement.from(statement.subject, statement.predicate, statement.object.subject))
            statement.object.each_statement(&block)
          else
            block.call(statement)
          end
        end
      end
    end
  end

  refine ::RDF::Graph do
    # Allow a graph to be treated as a term in a statement.
    include ::RDF::Term
  end
end
