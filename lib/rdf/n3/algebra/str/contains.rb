module RDF::N3::Algebra::Str
  ##
  # True iff the subject string contains the object string.
  class Contains < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strContains
  end
end
