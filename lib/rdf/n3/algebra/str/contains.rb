module RDF::N3::Algebra::Str
  # True iff the subject string contains the object string.
  class Contains < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Evaluatable
    include RDF::N3::Algebra::Builtin

    NAME = :strContains

    ##
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      case
      when !left.is_a?(RDF::Term) || !right.is_a?(RDF::Term) || !left.compatible?(right)
        log_error(NAME) {"expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"}
        RDF::Literal::FALSE
      when left.to_s.include?(right.to_s) then RDF::Literal::TRUE
      else RDF::Literal::FALSE
      end
    end
  end
end
