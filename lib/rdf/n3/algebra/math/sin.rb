module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the sine value of the subject.
  class Sin < RDF::N3::Algebra::LiteralOperator
    NAME = :mathSin

    ##
    # The math:sin operator takes string or number and calculates its sine.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        RDF::Literal(Math.sin(resource.as_number.object))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
