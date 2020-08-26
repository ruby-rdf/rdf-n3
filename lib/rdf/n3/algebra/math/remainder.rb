module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of integers. The object is calculated by dividing the first number of the pair by the second and taking the remainder.
  class Remainder < RDF::N3::Algebra::ListOperator
    NAME = :mathRemainder

    ##
    # The math:quotient operator takes a pair of strings or numbers and calculates their quotient.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      list.to_a.map do |li|
        li.is_a?(RDF::Literal::Numeric) ?
          li :
          RDF::Literal::Integer.new(li.value)
      end.reduce(&:%)
    end

    ##
    # The list argument must be a pair of literals.
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    # @see RDF::N3::ListOperator#validate
    def validate(list)
      if super && list.all?(&:literal?) && list.length == 2
        true
      else
        log_error(NAME) {"list is not a pair of literals: #{list.to_sxp}"}
        false
      end
    end
  end
end
