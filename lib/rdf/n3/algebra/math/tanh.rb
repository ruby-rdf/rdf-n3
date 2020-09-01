module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the tangent value of the subject.
  class TanH < RDF::N3::Algebra::LiteralOperator
    NAME = :mathTanH

    ##
    # The math:tanh operator takes string or number and calculates its hyperbolic tangent. The inverse hyperbolic tangent of a concrete object can also calculate a variable subject.
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
          RDF::Literal(Math.tanh(resource.as_number.object), canonicalize: true)
        when :object
          RDF::Literal(Math.atanh(resource.as_number.object), canonicalize: true)
        end
      else
        nil
      end
    end
  end
end
