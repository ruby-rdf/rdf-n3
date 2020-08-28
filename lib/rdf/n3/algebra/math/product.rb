module RDF::N3::Algebra::Math
  ##
  # The subject is a list of numbers. The object is calculated as the arithmentic product of those numbers.
  class Product < RDF::N3::Algebra::ListOperator
    NAME = :mathProduct

    ##
    # The math:product operator takes a list of strings or numbers and calculates their sum.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      list.to_a.map(&:as_number).reduce(&:*) || RDF::Literal(1)  # Empty list product is 1
    end
  end
end
