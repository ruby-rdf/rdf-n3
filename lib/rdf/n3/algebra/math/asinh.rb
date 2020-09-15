module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the inverse hyperbolic sine value of the subject.
  class ASinH < RDF::N3::Algebra::LiteralOperator
    NAME = :mathASinH

    ##
    # The math:asinh operator takes string or number and calculates its inverse hyperbolic sine.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(Math.asinh(resource.as_number.object))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
