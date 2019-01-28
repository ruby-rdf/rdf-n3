module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is NOT LESS than a number of which the object is a string representation.
  class NotLessThan < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathNotLessThan
  end
end
