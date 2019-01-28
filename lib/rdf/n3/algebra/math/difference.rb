module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of numbers. The object is calculated by subtracting the second number of the pair from the first.
  class Difference < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathDifference
  end
end
