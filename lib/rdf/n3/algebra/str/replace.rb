module RDF::N3::Algebra::Str
  class Replace < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :strReplace

    ##
    # A built-in for replacing characters or sub. takes a list of 3 strings; the first is the input data, the second the old and the third the new string. The object is calculated as the replaced string.
    #
    # @example
    #     ("fofof bar", "of", "baz") string:replace "fbazbaz bar"
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
      raise TypeError, "list must have exactly three entries" unless list.length == 3

      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        bound_entries = list.to_a.map {|op| op.evaluate(solution.bindings)}

        if bound_entries.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          input, old_str, new_str = bound_entries
          output = input.to_s.gsub(old_str.to_s, new_str.to_s)

          if result.variable?
            solution.merge(result.to_sym => RDF::Literal(output))
          elsif result != output
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
