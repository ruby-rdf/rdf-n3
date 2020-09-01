module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the inverse hyperbolic cosine value of the subject.
  class ACosH < RDF::N3::Algebra::LiteralOperator
    NAME = :mathACosH

    ##
    # The math:acosh operator takes string or number and calculates its inverse hyperbolic cosine.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        RDF::Literal(Math.acosh(resource.as_number.object))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
