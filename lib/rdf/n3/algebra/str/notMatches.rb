module RDF::N3::Algebra::Str
  ##
  # The subject string; the object is is a regular expression in the perl, python style. It is true iff the string does NOT match the regexp.
  class NotMatches < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strNotMatches
  end
end
