module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the subject rounded to the nearest integer.
  class Rounded < RDF::N3::Algebra::LiteralOperator
    NAME = :mathRounded

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
        as_literal(resource.as_number.round)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
