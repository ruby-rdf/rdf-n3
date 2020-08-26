module RDF::N3::Algebra::Math
  ##
  # The subject or object is calculated to be the negation of the other.
  class Negation < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :mathNegation

    ##
    # The math:negation operator takes may have either a bound subject or object.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        subject, object = operand(0), operand(1)

        log_debug(NAME) {"subject: #{subject.to_sxp}, object: #{object.to_sxp}"}
        unless subject.literal? || object.literal?
          log_error(NAME) {"subject or object are not literals: #{subject.inspect}, #{object.inspect}"}
          next
        end

        subject = RDF::Literal::Integer.new(subject.value) if subject.literal? && !subject.is_a?(RDF::Literal::Numeric)
        object = RDF::Literal::Integer.new(object.value) if object.literal? && !object.is_a?(RDF::Literal::Numeric)
        if subject.variable?
          solution.merge(subject.to_sym => -object)
        elsif object.variable?
          solution.merge(object.to_sym => -subject)
        elsif subject == -object
          solution
        else
          nil
        end
      end.compact)
    end
  end
end
