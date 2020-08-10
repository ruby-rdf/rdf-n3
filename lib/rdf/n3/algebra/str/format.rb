module RDF::N3::Algebra::Str
  class Format < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :strFormat

    ##
    # The subject is a list, whose first member is a format string, and whose remaining members are arguments to the format string. The formating string is in the style of python's % operator, very similar to C's sprintf(). The object is calculated from the subject.
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
          format, *args = bound_entries.map(&:value)
          str = format % args

          if result.variable?
            solution.merge(result.to_sym => str)
          elsif result != str
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
