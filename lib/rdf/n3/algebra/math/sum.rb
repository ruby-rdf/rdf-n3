module RDF::N3::Algebra::Math
  ##
  # The subject is a list of numbers. The object is calculated as the arithmentic sum of those numbers.
  #
  # @example
  #     { ("3" "5") math:sum ?x } => { ?x :valueOf "3 + 5" } .
  #     { (3 5) math:sum ?x } => { ?x :valueOf "3 + 5 = 8" } .
  class Sum < RDF::N3::Algebra::ListOperator
    NAME = :mathSum

    ##
    # Evaluates to the sum of the list elements
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      list.to_a.map do |li|
        li.is_a?(RDF::Literal::Numeric) ?
          li :
          RDF::Literal::Integer.new(li.value)
      end.reduce(&:+) || RDF::Literal(0)  # Empty list sums to 0
    end
  end
end
