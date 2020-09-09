module RDF::N3::Algebra::Str
  # True iff the subject string contains the object string.
  class Contains < SPARQL::Algebra::Operator::Contains
    include RDF::N3::Algebra::Builtin

    NAME = :strContains
  end
end
