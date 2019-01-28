module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is NOT EQUAL to a number of which the object is a string representation.
  class NotEqualTo < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathNotEqualTo
  end
end
