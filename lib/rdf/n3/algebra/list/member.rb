module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list and the object is in that list, then this is true.
  class Member < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :listMember

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
        object = operand(1).evaluate(solution.bindings) || operand(1)

        log_debug(NAME) {"list: #{list.to_sxp}, object: #{object.to_sxp}"}
        unless list.list? && list.valid?
          log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
          next
        end

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          if object.variable?
            # Bind all list entries to this solution, creates an array of solutions
            list.to_a.map do |term|
              solution.merge(object.to_sym => term)
            end
          elsif list.to_a.include?(object)
            solution
          else
            nil
          end
        end
      end.flatten.compact)
    end
  end
end
