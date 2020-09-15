module RDF::N3::Algebra::Log
  ##
  # Equality in this sense is actually the same URI. A cwm built-in logical operator.
  class NotEqualTo < SPARQL::Algebra::Operator::SameTerm
    include RDF::N3::Algebra::Builtin
    NAME = :logNotEqualTo

    ##
    # Returns `true` if the operands are not the same RDF term; returns
    # `false` otherwise.
    #
    # @param  [RDF::Term] term1
    #   an RDF term
    # @param  [RDF::Term] term2
    #   an RDF term
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if either operand is unbound
    def apply(term1, term2)
      RDF::Literal(!term1.eql?(term2))
    end
  end
end
