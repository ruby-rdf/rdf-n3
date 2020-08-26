module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of numbers. The object is calculated by subtracting the second number of the pair from the first.
  #
  # @example
  #     { ("8" "3") math:difference ?x} => { ?x :valueOf "8 - 3" } .
  #     { ("8") math:difference ?x } => { ?x :valueOf "8 - (error?)" } .
  #     { (8 3) math:difference ?x} => { ?x :valueOf "8 - 3" } .
  class Difference < RDF::N3::Algebra::ListOperator
    NAME = :mathDifference

    ##
    # The math:difference operator takes a pair of strings or numbers and calculates their difference.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      list.to_a.map do |li|
        li.is_a?(RDF::Literal::Numeric) ?
          li :
          RDF::Literal::Integer.new(li.value)
      end.reduce(&:-)
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
