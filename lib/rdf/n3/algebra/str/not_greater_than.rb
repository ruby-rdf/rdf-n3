module RDF::N3::Algebra::Str
  # True iff the string is NOT greater than the object when ordered according to Unicode(tm) code order.
  class NotGreaterThan < GreaterThan
    NAME = :strNotGreaterThan

    ##
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      RDF::Literal(super != RDF::Literal::TRUE)
    end
  end
end
