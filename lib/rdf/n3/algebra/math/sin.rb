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
          as_literal(Math.sin(resource.as_number.object))
        when :object
          as_literal(Math.sinh(resource.as_number.object))
        end
      else
        nil
      end
    end

    ##
    # Input is either the subject or object
    #
    # @return [RDF::Term]
    def input_operand
      RDF::N3::List.new(values: operands)
    end
  end
end
