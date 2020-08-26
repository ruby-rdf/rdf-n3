module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of numbers. The object is calculated by raising the first number of the power of the second.
  class Exponentiation < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :mathExponentiation

    ##
    # The math:difference operator takes a pair of strings or numbers and calculates the exponent.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      result = operand(1)

      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        # Might be a variable or node evaluating to a list in queryable, or might be a list with variables
        list = operand(0).evaluate(solution.bindings)
        # If it evaluated to a BNode, re-expand as a list
        list = RDF::N3::List.try_list(list, queryable).evaluate(solution.bindings)

        log_debug(NAME) {"list: #{list.to_sxp}, result: #{result.to_sxp}"}
        unless list.list? && list.valid?
          log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
          next
        end
        unless list.all?(&:literal?) && list.length == 2
          log_error(NAME) {"list is not a pair of literals: #{list.to_sxp}"}
          next
        end

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          rhs = list.to_a.map {|li| li.is_a?(RDF::Literal::Numeric) ? li : RDF::Literal::Integer.new(li.value)}.reduce(&:**)

          if result.variable?
            solution.merge(result.to_sym => rhs)
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
