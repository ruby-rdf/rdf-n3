module RDF::N3::Algebra::Str
  ##
  # The subject is a list, whose first member is a format string, and whose remaining members are arguments to the format string. The formating string is in the style of python's % operator, very similar to C's sprintf(). The object is calculated from the subject.
  class Format < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strFormat
  end
end
