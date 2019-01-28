module RDF::N3::Algebra::Str
  ##
  # True iff the subject string is the NOT same as object string ignoring differences between upper and lower case.
  class NotEqualIgnoringCase < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strNotEqualIgnoringCase
  end
end
