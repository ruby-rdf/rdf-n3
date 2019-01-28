module RDF::N3::Algebra::Str
  ##
  # The subject is a string; the object is is a regular expression in the perl, python style. It is true iff the string matches the regexp.
  class Matches < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strMatches
  end
end
