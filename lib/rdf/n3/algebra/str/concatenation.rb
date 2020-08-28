module RDF::N3::Algebra::Str
  ##
  # The subject is a list of strings. The object is calculated as a concatenation of those strings.
  #
  # @example
  #     ("a" "b") string:concatenation :s
  class Concatenation < RDF::N3::Algebra::ListOperator
    NAME = :strConcatenation

    ##
    # The string:concatenation operator takes a list of terms evaluating to strings and either binds the result of concatenating them to the output variable, removes a solution that does equal.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      RDF::Literal(list.to_a.map{|li| li.is_a?(RDF::Literal::Double) ? li.canonicalize.to_s.downcase : li.canonicalize}.join(""))
    end
  end
end
