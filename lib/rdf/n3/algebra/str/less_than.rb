module RDF::N3::Algebra::Str
  # True iff the string is less than the object when ordered according to Unicode(tm) code order.
  class LessThan < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Evaluatable
    include RDF::N3::Algebra::Builtin

    NAME = :strLessThan

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
      when left < right then RDF::Literal::TRUE
      else RDF::Literal::FALSE
      end
    end
  end
end
