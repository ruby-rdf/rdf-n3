module RDF::N3::Algebra::Str
  ##
  # True iff the string is less than the object when ordered according to Unicode(tm) code order.
  class LessThan < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strLessThan
  end
end
