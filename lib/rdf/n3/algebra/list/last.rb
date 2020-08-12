module RDF::N3::Algebra::List
  ##
  # Iff the suject is a list and the object is the last thing that list, then this is true. The object can be calculated as a function of the list.
  #
  # @example
  #     { ( 1 2 3 4 5 6 ) list:last 6 } => { :test1 a :SUCCESS }.
  #
  # The object can be calculated as a function of the list.
  class Last < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :listLast

    ##
    # Evaluates this operator using the given variable `bindings`.
    # If the last operand is a variable, it creates a solution for each element in the list.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    # @raise  [TypeError] if operands are not compatible
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        list = operand(0)
        result = operand(1)

        case list
        when RDF::Node, RDF::Query::Variable
          # Attempt to bind a node or variable to a list
          list = list.evaluate(solution.bindings)
        when RDF::List
          # Attempt to bind list elements
          list = list.to_a.map {|op| op.evaluate(solution.bindings)}
        end
        log_debug(NAME) {"list: #{list.to_sxp}, result: #{result.to_sxp}"}

        #require 'byebug'; byebug
        if list.to_a.any? {|op| op.variable? && op.unbound?}
          # Can't bind list elements
          solution
        else
          if result.variable?
            solution.merge(result.to_sym => list.last)
          elsif list.last == result
            solution
          else
            nil
          end
        end
      end.compact)
    end
  end
end
