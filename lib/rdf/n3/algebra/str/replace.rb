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
        unless list.length == 3
          log_error(NAME) {"list must have exactly three entries: #{list.to_sxp}"}
          next
        end

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          input, old_str, new_str = list.to_a
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
  end
end
