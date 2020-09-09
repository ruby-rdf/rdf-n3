module RDF::N3::Algebra::Math
  ##
  # The subject or object is calculated to be the negation of the other.
  class Negation < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger
    include RDF::N3::Algebra::Builtin

    NAME = :mathNegation

    ##
    # The math:negation operator takes may have either a bound subject or object.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case resource
      when RDF::Query::Variable
        resource
      when RDF::Literal
        as_literal(-resource.as_number)
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
