module RDF::N3::Algebra::Log
  ##
  # Equality in this sense is actually the same URI. A cwm built-in logical operator.
  class NotEqualTo < SPARQL::Algebra::Operator::Binary
    NAME = :logNotEqualTo
  end
end
