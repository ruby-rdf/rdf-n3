module RDF::N3::Algebra::Str
  ##
  # True iff the string is NOT greater than the object when ordered according to Unicode(tm) code order.
  class NotGreaterThan < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strNotGreaterThan
  end
end
