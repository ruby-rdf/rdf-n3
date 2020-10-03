module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is EQUAL TO a number of which the object is a string representation.
  class EqualTo < SPARQL::Algebra::Operator::Compare
    include RDF::N3::Algebra::Builtin

    NAME = :'='

    ##
    # Returns TRUE if `term1` and `term2` are the same RDF term as defined in Resource Description Framework (RDF): Concepts and Abstract Syntax [CONCEPTS]; produces a type error if the arguments are both literal but are not the same RDF term *; returns FALSE otherwise. `term1` and `term2` are the same if any of the following is true:
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
      log_debug(NAME) { "term1: #{term1.to_sxp} == term2: #{term2.to_sxp} ? #{(term1 == term2).inspect}"}
      RDF::Literal(term1.as_number == term2.as_number)
    end
  end
end
