module RDF::N3::Algebra::Str
  # True iff the subject string contains the object string, with the comparison done ignoring the difference between upper case and lower case characters.
  class ContainsIgnoringCase < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Evaluatable
    include RDF::N3::Algebra::Builtin

    NAME = :strContainsIgnoringCase

    ##
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      case
      when !left.compatible?(right)
        log_error(NAME) {"expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"}
        RDF::Literal::FALSE
      when left.to_s.downcase.include?(right.to_s.downcase) then RDF::Literal::TRUE
      else RDF::Literal::FALSE
      end
    end
  end
end
