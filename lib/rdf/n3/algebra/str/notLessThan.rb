module RDF::N3::Algebra::Str
  ##
  # True iff the string is NOT less than the object when ordered according to Unicode(tm) code order.
  class NotLessThan < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strNotLessThan
  end
end
