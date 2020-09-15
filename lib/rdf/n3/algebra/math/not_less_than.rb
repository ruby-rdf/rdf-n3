module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is NOT LESS than a number of which the object is a string representation.
  class NotLessThan < SPARQL::Algebra::Operator::Compare
    include RDF::N3::Algebra::Builtin

    NAME = :'>='

    ##
    # Returns TRUE if `term1` is greater than or equal to `term2`.
    #
    # @param  [RDF::Term] term1
    #   an RDF term
    # @param  [RDF::Term] term2
    #   an RDF term
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if either operand is not an RDF term or operands are not comperable
    #
    # @see RDF::Term#==
    def apply(term1, term2)
      log_debug(NAME) { "term1: #{term1.to_sxp} >= term2: #{term2.to_sxp} ? #{(term1 >= term2).inspect}"}
      RDF::Literal(term1 >= term2)
    end
  end
end
