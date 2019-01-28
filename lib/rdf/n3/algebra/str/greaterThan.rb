module RDF::N3::Algebra::Str
  ##
  # True iff the string is greater than the object when ordered according to Unicode(tm) code order
  class GreaterThan < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strGreaterThan
  end
end
