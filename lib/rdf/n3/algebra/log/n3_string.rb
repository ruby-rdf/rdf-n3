module RDF::N3::Algebra::Log
  ##
  # The subject formula, expressed as N3, gives this string.
  class N3String < RDF::N3::Algebra::LiteralOperator
    NAME = :logN3String

    ##
    # Serializes the subject formula into an N3 string representation.
    #
    # @param [RDF::N3::List] resource
    # @return [RDF::Term]
    def evaluate(resource, position: :subject)
      case position
      when :subject
        return nil unless resource.formula?
        as_literal(RDF::N3::Writer.buffer {|w| resource.each {|st| w << st}})
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end

    ##
    # Subject must evaluate to a formula and object to a literal.
    #
    # @param [RDF::Term] subject
    # @param [RDF::Term] object
    # @return [Boolean]
    def valid?(subject, object)
      subject.formula? && (object.variable? || object.literal?)
    end
  end
end
