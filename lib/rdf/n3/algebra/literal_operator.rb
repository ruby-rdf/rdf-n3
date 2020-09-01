module RDF::N3::Algebra
  ##
  # This is a generic operator where the subject is a literal or binds to a literal and the object is either a constant that equals the evaluation of the subject, or a variable to which the result is bound in a solution
  class LiteralOperator < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    ##
    # The operator takes a literal and provides a mechanism for subclasses to operate over (and validate) that argument.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        subject = operand(0).evaluate(solution.bindings) || operand(0)
        object = operand(1).evaluate(solution.bindings) || operand(1)

        log_debug(self.class.const_get(:NAME)) {"subject: #{subject.to_sxp}, object: #{object.to_sxp}"}

        lhs = evaluate(subject, position: :subject)
        if lhs.nil?
          log_error(self.class.const_get(:NAME)) {"subject is invalid: #{subject.inspect}"}
          next
        end

        rhs = evaluate(object, position: :object)
        if lhs.nil?
          log_error(self.class.const_get(:NAME)) {"object is invalid: #{object.inspect}"}
          next
        end
        next unless valid?(subject, object)

        if object.variable?
          solution.merge(object.to_sym => lhs)
        elsif subject.variable?
          solution.merge(subject.to_sym => rhs)
        elsif rhs != lhs
          nil
        else
          solution
        end
      end.compact)
    end

    ##
    # Subclasses implement `evaluate`.
    #
    # Returns nil if resource does not validate, given its position
    #
    # @param [RDF::N3::List] resource
    # @return [RDF::Term]
    def evaluate(resource, position: :subject)
      raise NotImplemented
    end

    ##
    # Subclasses may override or supplement validate to perform validation on the list subject
    #
    # @param [RDF::Term] subject
    # @param [RDF::Term] object
    # @return [Boolean]
    def valid?(subject, object)
      true
    end
  end
end
