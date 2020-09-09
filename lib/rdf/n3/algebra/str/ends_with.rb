module RDF::N3::Algebra::Str
  # True iff the subject string ends with the object string.
  class EndsWith < SPARQL::Algebra::Operator::StrEnds
    include RDF::N3::Algebra::Builtin

    NAME = :strEndsWith
  end
end
