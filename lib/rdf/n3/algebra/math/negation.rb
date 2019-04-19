module RDF::N3::Algebra::Math
  ##
  # The subject or object is calculated to be the negation of the other.
  class Negation < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathNegation
  end
end
