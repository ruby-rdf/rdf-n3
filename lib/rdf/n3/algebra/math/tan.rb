module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the tangent value of the subject.
  class Tan < RDF::N3::Algebra::LiteralOperator
    NAME = :mathTan

    ##
    # The math:tan operator takes string or number and calculates its tangent. The arc tangent of a concrete object can also calculate a variable subject.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case resource
      when RDF::Query::Variable then resource
      when RDF::Literal
        case position
        when :subject
          RDF::Literal(Math.tan(resource.as_number.object), canonicalize: true)
        when :object
          RDF::Literal(Math.atan(resource.as_number.object), canonicalize: true)
        end
      else
        nil
      end
    end
  end
end
