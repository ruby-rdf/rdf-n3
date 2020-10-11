module RDF::N3::Algebra::Math
  ##
  # **schema**:
  # `$a1 math:equalTo $a2`
  # 
  # **summary**:
  # checks equality of numbers
  # 
  # **definition**:
  # `true` if and only if `$a1` is equal to `$a2`. 
  # Requires both arguments to be either concrete numerals, or variables bound to a numeral.
  # 
  # **literal domains**:
  # 
  # * `$a1`: `xs:decimal` (or its derived types), `xs:float`, or `xs:double`  (see note on type promotion, and casting from string)
  # * `$a2`: `xs:decimal` (or its derived types), `xs:float`, or `xs:double`  (see note on type promotion, and casting from string)
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-equal
  class EqualTo < SPARQL::Algebra::Operator::Compare
    include RDF::N3::Algebra::Builtin

    NAME = :'='

    ##
    # The math:equalTo operator takes a pair of strings or numbers and determines if they are the same numeric value.
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
      return RDF::Literal::FALSE unless term1.is_a?(RDF::Term) && term2.is_a?(RDF::Term)
      log_debug(NAME) { "term1: #{term1.to_sxp} == term2: #{term2.to_sxp} ? #{(term1.as_number == term2.as_number).inspect}"}
      RDF::Literal(term1.as_number == term2.as_number)
    end
  end
end
