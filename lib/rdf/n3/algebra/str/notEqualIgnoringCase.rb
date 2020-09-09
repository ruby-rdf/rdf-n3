module RDF::N3::Algebra::Str
  # True iff the subject string is the NOT same as object string ignoring differences between upper and lower case.
  class NotEqualIgnoringCase < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Evaluatable
    include RDF::Util::Logger
    include RDF::N3::Algebra::Builtin

    NAME = :strNotEqualIgnoringCase

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
      when left.to_s.downcase != right.to_s.downcase then RDF::Literal::TRUE
      else RDF::Literal::FALSE
      end
    end
  end
end
