module RDF::N3::Algebra
  ##
  # True if the subject and object are the same RDF node (symbol or literal).  Do not confuse with owl:sameAs. A cwm built-in logical operator, RDF graph level.
  class LogEqualTo < SPARQL::Algebra::Operator::Binary
    NAME = :logEqualTo
  end
end
