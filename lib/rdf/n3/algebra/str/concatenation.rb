module RDF::N3::Algebra::Str
  ##
  # The subject is a list of strings. The object is calculated as a concatenation of those strings.
  #
  # @example
  #     ("a" "b") string:concatenation :s
  class Concatenation < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :strConcatenation

    ##
    # The string:concatenation operator takes a list of terms evaluating to strings and either binds the result of concatenating them to the output variable, removes a solution that does equal.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    # @raise  [TypeError] if operands are not compatible
    def execute(queryable, solutions:, **options)
      result = operand(1)

      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        # Might be a variable or node evaluating to a list in queryable, or might be a list with variables
        list = operand(0).evaluate(solution.bindings)
        # If it evaluated to a BNode, re-expand as a list
        list = RDF::N3::List.try_list(list, queryable).evaluate(solution.bindings)

        log_debug(NAME) {"list: #{list.to_sxp}, result: #{result.to_sxp}"}
        raise TypeError, "operand is not a list" unless list.list? && list.valid?

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          rhs = list.to_a.map(&:value).join("")

          if result.variable?
            solution.merge(result.to_sym => RDF::Literal(rhs))
          elsif result != rhs
            nil
          else
            solution
          end
        end
      end.compact)
    end
  end
end
