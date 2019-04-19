module RDF::N3::Algebra::Str
  ##
  # The subject is a list of strings. The object is calculated as a concatenation of those strings.
  class Concatenation < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strConcatenation
  end
end
