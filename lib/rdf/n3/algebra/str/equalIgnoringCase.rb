module RDF::N3::Algebra::Str
  ##
  # True iff the subject string is the same as object string ignoring differences between upper and lower case.
  class EqualIgnoringCase < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strEqualIgnoringCase
  end
end
