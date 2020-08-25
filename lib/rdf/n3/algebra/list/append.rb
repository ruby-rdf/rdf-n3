module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list of lists and the concatenation of all those lists  is the object, then this is true. The object can be calculated as a function of the subject.
  #
  # @example
  #     ( (1 2) (3 4) ) list:append (1 2 3 4).
  #
  # The object can be calculated as a function of the subject.
  class Append < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :listAppend

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
        unless list.to_a.all? {|li| li.list?}
          log_error(NAME) {"operand is not a list of lists: #{list.to_sxp}"}
          next
        end

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          flattened = list.to_a.map(&:to_a).flatten
          if result.variable?
            # Bind a new list based on the values, whos subject use made up from original list subjects
            subj = RDF::Node.intern(list.map(&:subject).hash)
            solution.merge(result.to_sym => RDF::N3::List.new(subject: subj, values: list.to_a.map(&:to_a).flatten))
          elsif result.to_a == flattened
            solution
          else
            nil
          end
        end
      end.compact)
    end
  end
end
