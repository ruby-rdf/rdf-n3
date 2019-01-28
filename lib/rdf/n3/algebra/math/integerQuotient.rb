module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of integer numbers. The object is calculated by dividing the first number of the pair by the second, ignoring remainder.
  class IntegerQuotient < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathIntegerQuotient
  end
end
