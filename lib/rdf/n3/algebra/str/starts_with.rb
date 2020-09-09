module RDF::N3::Algebra::Str
  # True iff the subject string starts with the object string.
  class StartsWith < SPARQL::Algebra::Operator::StrStarts
    include RDF::N3::Algebra::Builtin

    NAME = :strStartsWith
  end
end
