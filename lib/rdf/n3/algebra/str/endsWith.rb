module RDF::N3::Algebra::Str
  ##
  # True iff the subject string ends with the object string.
  class EndsWith < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strEndsWith
  end
end
