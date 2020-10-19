module RDF::N3::Algebra::Log
  ##
  # True if the subject and object are the same RDF node (symbol or literal).  Do not confuse with owl:sameAs. A cwm built-in logical operator, RDF graph level.
  class EqualTo < RDF::N3::Algebra::ResourceOperator
    NAME = :logEqualTo

    ##
    # Resolves inputs as terms.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Literal]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource if resource.term?
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end

    ##
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      left.sameTerm?(right)
    end
  end
end
