module RDF::N3::Algebra::Math
  ##
  # The subject is a list of numbers. The object is calculated as the arithmentic sum of those numbers.
  class Sum < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathSum
  end
end
