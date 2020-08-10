module RDF::N3::Algebra::Str
  class Scrape < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :strScrape

    ##
    # The subject is a list of two strings. The second string is a regular expression in the perl, python style. It must contain one group (a part in parentheses).  If the first string in the list matches the regular expression, then the object is calculated as being the part of the first string which matches the group.
    #
    # @example
    #     ("abcdef" "ab(..)ef") string:scrape "cd"
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
      raise TypeError, "list must have exactly two entries" unless list.length == 2

      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        bound_entries = list.to_a.map {|op| op.evaluate(solution.bindings)}

        if bound_entries.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          input, regex = bound_entries
          md = Regexp.new(regex.to_s).match(input.to_s)

          if result.variable? && md && md[1]
            solution.merge(result.to_sym => RDF::Literal(md[1]))
          elsif !md || result != md[1]
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
