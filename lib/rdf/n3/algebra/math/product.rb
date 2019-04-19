module RDF::N3::Algebra::Math
  ##
  # The subject is a list of numbers. The object is calculated as the arithmentic product of those numbers.
  class Product < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathProduct
  end
end
