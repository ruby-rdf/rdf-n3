module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of numbers. The object is calculated by dividing the first number of the pair by the second.
  class Quotient < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathQuotient
  end
end
