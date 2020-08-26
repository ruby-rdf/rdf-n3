module RDF::N3::Algebra::Math
  ##
  # The object is calculated as the subject upwards to a whole number.
  class Ceiling < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :mathCeiling

    ##
    # The math:ceiling operator takes string or number and calculates its ceiling.
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

        num = RDF::Literal::Double.new(num.value) unless num.is_a?(RDF::Literal::Numeric)
        num = num.ceil

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
