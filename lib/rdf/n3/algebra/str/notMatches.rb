module RDF::N3::Algebra::Str
  # The subject string; the object is a regular expression in the perl, python style. It is true iff the string does NOT match the regexp.
  class NotMatches < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Evaluatable
    include RDF::N3::Algebra::Builtin

    NAME = :strNotMatches

    ##
    # @param  [RDF::Literal] text
    #   a simple literal
    # @param  [RDF::Literal] pattern
    #   a simple literal
    # @return [RDF::Literal::Boolean] `true` or `false`
    def apply(text, pattern)
      # @see https://www.w3.org/TR/xpath-functions/#regex-syntax
      log_error(NAME) {"expected a plain RDF::Literal, but got #{text.inspect}"} unless text.is_a?(RDF::Literal) && text.plain?
      text = text.to_s
      # TODO: validate text syntax

      # @see https://www.w3.org/TR/xpath-functions/#regex-syntax
      log_error(NAME) {"expected a plain RDF::Literal, but got #{pattern.inspect}"} unless pattern.is_a?(RDF::Literal) && pattern.plain?
      pattern = pattern.to_s

      RDF::Literal(!Regexp.new(pattern).match?(text))
    end
  end
end
