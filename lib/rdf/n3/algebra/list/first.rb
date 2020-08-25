module RDF::N3::Algebra::List
  ##
  # Iff the suject is a list and the object is the first thing that list, then this is true. The object can be calculated as a function of the list.
  #
  # @example
  #     { ( 1 2 3 4 5 6 ) list:first 1 } => { :test1 a :SUCCESS }.
  #
  # The object can be calculated as a function of the list.
  class First < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :listFirst

    ##
    # Evaluates this operator using the given variable `bindings`.
    # If the last operand is a variable, it creates a solution for each element in the list.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        list = operand(0).evaluate(solution.bindings)
        list = RDF::N3::List.try_list(list, queryable).evaluate(solution.bindings)

        result = operand(1)

        log_debug(NAME) {"list: #{list.to_sxp}, result: #{result.to_sxp}"}
        unless list.list? && list.valid?
          log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
          next
        end

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          if result.variable?
            solution.merge(result.to_sym => list.first)
          elsif list.first == result
            solution
          else
            nil
          end
        end
      end.compact)
    end
  end
end
