module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of integers. The object is calculated by dividing the first number of the pair by the second and taking the remainder.
  class Remainder < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathRemainder
  end
end
