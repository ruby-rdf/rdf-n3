module RDF::N3::Algebra::Str
  ##
  # True iff the subject string contains the object string, with the comparison done ignoring the difference between upper case and lower case characters.
  class ContainsIgnoringCase < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strContainsIgnoringCase
  end
end
