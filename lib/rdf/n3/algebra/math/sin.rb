module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the sine value of the subject.
  class Sin < RDF::N3::Algebra::LiteralOperator
    NAME = :mathSin

    ##
    # The math:sin operator takes string or number and calculates its sine. The arc sine of a concrete object can also calculate a variable subject.
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
          RDF::Literal(Math.sin(resource.as_number.object), canonicalize: true)
        when :object
          RDF::Literal(Math.asin(resource.as_number.object), canonicalize: true)
        end
      else
        nil
      end
    end
  end
end
