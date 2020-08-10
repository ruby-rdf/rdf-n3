module RDF::N3::Algebra::Str
  class ContainsIgnoringCase < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Evaluatable
    include RDF::Util::Logger

    NAME = :strContainsIgnoringCase

    ##
    # True iff the subject string contains the object string, with the comparison done ignoring the difference between upper case and lower case characters.
    #
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    # @raise  [TypeError] if operands are not compatible
    def apply(left, right)
      case
      when !left.compatible?(right)
        raise TypeError, "expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"
      when left.to_s.downcase.include?(right.to_s.downcase) then RDF::Literal::TRUE
      else RDF::Literal::FALSE
      end
    end
  end
end
