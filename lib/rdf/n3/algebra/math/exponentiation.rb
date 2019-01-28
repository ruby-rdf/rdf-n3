module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of numbers. The object is calculated by raising the first number of the power of the second.
  class Exponentiation < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathExponentiation
  end
end
