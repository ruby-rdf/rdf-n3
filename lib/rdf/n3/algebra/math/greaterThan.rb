module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is greater than the number of which the object is a string representation.
  class GreaterThan < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathGreaterThan
  end
end
