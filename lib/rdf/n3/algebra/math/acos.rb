module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the arc cosine value of the subject.
  class ACos < RDF::N3::Algebra::LiteralOperator
    NAME = :mathACos

    ##
    # The math:acos operator takes string or number and calculates its arc cosine.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        RDF::Literal(Math.acos(resource.as_number.object), canonicalize: true)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
