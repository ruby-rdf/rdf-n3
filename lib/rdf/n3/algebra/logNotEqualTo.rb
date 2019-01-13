module RDF::N3::Algebra
  ##
  # Equality in this sense is actually the same URI. A cwm built-in logical operator.
  class LogNotEqualTo < SPARQL::Algebra::Operator::Binary
    NAME = :logNotEqualTo
  end
end
