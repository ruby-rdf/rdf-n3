module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of integer numbers. The object is calculated by dividing the first number of the pair by the second, ignoring remainder.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-integer-divide
  class IntegerQuotient < RDF::N3::Algebra::Math::Quotient
    NAME = :mathIntegerQuotient

    ##
    # The math:quotient operator takes a pair of strings or numbers and calculates their quotient.
    #
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      RDF::Literal::Integer.new(super)
    end
  end
end
