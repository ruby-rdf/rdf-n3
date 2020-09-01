module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the inverse hyperbolic tangent value of the subject.
  class ATanH < RDF::N3::Algebra::LiteralOperator
    NAME = :mathATanH

    ##
    # The math:atanh operator takes string or number and calculates its inverse hyperbolic tangent.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        RDF::Literal(Math.atanh(resource.as_number.object), canonicalize: true)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
