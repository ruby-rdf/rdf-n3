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
      list = operand(0)
      result = operand(1)

      log_debug(NAME) {"list: #{list.to_sxp}, result: #{result.to_sxp}"}

      raise TypeError, "operand is not a list" unless list.list? && list.valid?

      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        bound_entries = list.to_a.map {|op| op.evaluate(solution.bindings)}

        if bound_entries.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          rhs = bound_entries.map(&:value).join("")

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

    ##
    # Does not yield statements.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    def each(&block)
    end
  end
end
