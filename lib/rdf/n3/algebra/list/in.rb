module RDF::N3::Algebra::List
  ##
  # Iff the object is a list and the subject is in that list, then this is true.
  #
  # @example
  #     { 1 list:in  (  1 2 3 4 5 ) } => { :test4a a :SUCCESS }.
  class In < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :listIn

    ##
    # Evaluates this operator using the given variable `bindings`.
    # If the first operand is a variable, it creates a solution for each element in the list.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    # @raise  [TypeError] if operands are not compatible
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        subject = operand(0)
        list = operand(1)

        case list
        when RDF::Node, RDF::Query::Variable
          # Attempt to bind a node or variable to a list
          list = list.evaluate(solution.bindings)
        when RDF::List
          # Attempt to bind list elements
          list = list.to_a.map {|op| op.evaluate(solution.bindings)}
        end
        log_debug(NAME) {"subject: #{subject.to_sxp}, list: #{list.to_sxp}"}

        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          if subject.variable?
            # Bind all list entries to this solution, creates an array of solutions
            list.to_a.map do |term|
              solution.merge(subject.to_sym => term)
            end
          elsif list.to_a.include?(subject)
            solution
          else
            nil
          end
        end
      end.flatten.compact)
    end
  end
end
