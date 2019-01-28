module RDF::N3::Algebra::Str
  ##
  # True iff the subject string starts with the object string.
  class StartsWith < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strStartsWith
  end
end
