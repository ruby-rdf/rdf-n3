module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is EQUAL TO a number of which the object is a string representation.
  class EqualTo < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathEqualTo
  end
end
