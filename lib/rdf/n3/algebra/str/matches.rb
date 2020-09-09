module RDF::N3::Algebra::Str
  # The subject is a string; the object is is a regular expression in the perl, python style.
  # It is true iff the string matches the regexp.
  class Matches < SPARQL::Algebra::Operator::Regex
    include RDF::N3::Algebra::Builtin

    NAME = :strMatches
  end
end
