module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the tangent value of the subject.
  class TanH < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :mathTanH

    ##
    # The math:tanh operator takes string or number and calculates its hyperbolic tangent.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      num = operand(0)
      result = operand(1)

      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        log_debug(NAME) {"num: #{num.to_sxp}, result: #{result.to_sxp}"}
        unless num.literal?
          log_error(NAME) {"num is not a literal: #{num.inspect}"}
          next
        end

        num = RDF::Literal(Math.tanh(num.as_number.object))

        if result.variable?
          solution.merge(result.to_sym => num)
        elsif result != num
          nil
        else
          solution
        end
      end.compact)
    end
  end
end
