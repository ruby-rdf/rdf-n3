module RDF::N3::Algebra::Log
  ##
  # True if the subject and object are the same RDF node (symbol or literal).  Do not confuse with owl:sameAs. A cwm built-in logical operator, RDF graph level.
  class EqualTo < SPARQL::Algebra::Operator::SameTerm
    include RDF::N3::Algebra::Builtin
    NAME = :logEqualTo
  end
end
