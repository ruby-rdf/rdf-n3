module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the cosine value of the subject.
  class Cos < RDF::N3::Algebra::LiteralOperator
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :mathCos

    ##
    # The math:cos operator takes string or number and calculates its cosine. The arc cosine of a concrete object can also calculate a variable subject.
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
          as_literal(Math.cos(resource.as_number.object))
        when :object
          as_literal(Math.acos(resource.as_number.object))
        end
      else
        nil
      end
    end
  end
end