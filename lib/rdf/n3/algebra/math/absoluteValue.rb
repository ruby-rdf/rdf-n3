module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the absolute value of the subject.
  class AbsoluteValue < RDF::N3::Algebra::LiteralOperator
    NAME = :mathAbsoluteValue

    ##
    # The math:sum operator takes string or number and calculates its absolute value.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(resource.as_number.abs)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
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
