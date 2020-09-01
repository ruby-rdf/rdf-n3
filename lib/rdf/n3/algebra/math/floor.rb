module RDF::N3::Algebra::Math
  ##
  # The object is calculated as the subject downwards to a whole number.
  class Floor < RDF::N3::Algebra::LiteralOperator
    NAME = :mathFloor

    ##
    # The math:floor operator takes string or number and calculates its floor.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        RDF::Literal(resource.as_number.floor)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
