module RDF::N3::Algebra::List
  ##
  # Iff the suject is a list and the object is the first thing that list, then this is true. The object can be calculated as a function of the list.
  #
  # @example
  #     { ( 1 2 3 4 5 6 ) list:first 1 } => { :test1 a :SUCCESS }.
  #
  # The object can be calculated as a function of the list.
  class First < RDF::N3::Algebra::ListOperator
    NAME = :listFirst

    ##
    # Evaluates this operator using the given variable `bindings`.
    # If the last operand is a variable, it creates a solution for each element in the list.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      list.first
    end
  end
end
