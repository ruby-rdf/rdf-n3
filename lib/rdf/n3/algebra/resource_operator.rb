module RDF::N3::Algebra
  ##
  # This is a generic operator where the subject is a literal or binds to a literal and the object is either a constant that equals the evaluation of the subject, or a variable to which the result is bound in a solution
  class ResourceOperator < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    ##
    # The operator takes a literal and provides a mechanism for subclasses to operate over (and validate) that argument.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        subject = operand(0).evaluate(solution.bindings, formulae: formulae) || operand(0)
        object = operand(1).evaluate(solution.bindings, formulae: formulae) || operand(1)
        subject = formulae.fetch(subject, subject) if subject.node?
        object = formulae.fetch(object, object) if object.node?

        log_debug(self.class.const_get(:NAME)) {"subject: #{subject.to_sxp}, object: #{object.to_sxp}"}
        next unless valid?(subject, object)

        lhs = evaluate(subject, position: :subject)
        if lhs.nil?
          log_error(self.class.const_get(:NAME)) {"subject is invalid: #{subject.inspect}"}
          next
        end

        rhs = evaluate(object, position: :object)
        if rhs.nil?
          log_error(self.class.const_get(:NAME)) {"object is invalid: #{object.inspect}"}
          next
        end

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
    # Input is generically the subject
    #
    # @return [RDF::Term]
    def input_operand
      operand(0)
    end

    ##
    # Subclasses implement `evaluate`.
    #
    # Returns nil if resource does not validate, given its position
    #
    # @param [RDF::Term] resource
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

    ##
    # Returns a literal for the numeric argument, with doubles canonicalized using a lower-case 'e'.
    def as_literal(object)
      case object
      when Float
        literal = RDF::Literal(object, canonicalize: true)
        literal.instance_variable_set(:@string, literal.to_s.downcase)
        literal
      else
        RDF::Literal(object, canonicalize: true)
      end
    end
  end
end
