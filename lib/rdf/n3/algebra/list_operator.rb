module RDF::N3::Algebra
  ##
  # This is a generic operator where the subject is a list or binds to a list and the object is either a constant that equals the evaluation of the subject, or a variable to which the result is bound in a solution
  class ListOperator < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    ##
    # The operator takes a list and provides a mechanism for subclasses to operate over (and validate) that list argument.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [RDF::Query::Solutions] solutions
    #   solutions for chained queries
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        # Might be a variable or node evaluating to a list in queryable, or might be a list with variables
        list = operand(0).evaluate(solution.bindings, formulae: formulae)
        next unless list
        # If it evaluated to a BNode, re-expand as a list
        list = RDF::N3::List.try_list(list, queryable).evaluate(solution.bindings, formulae: formulae)
        object = operand(1).evaluate(solution.bindings, formulae: formulae) || operand(1)
        object = formulae.fetch(object, object).dup if object.node?

        log_debug(self.class.const_get(:NAME)) {"list: #{SXP::Generator.string(list.to_sxp_bin).gsub(/\s+/m, ' ')}, object: #{SXP::Generator.string(object.to_sxp_bin).gsub(/\s+/m, ' ')}"}
        next unless validate(list)

        lhs = evaluate(list)

        if object.variable?
          solution.merge(object.to_sym => lhs)
        elsif object != lhs
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
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    def evaluate(list)
      raise NotImplemented
    end

    ##
    # Subclasses may override or supplement validate to perform validation on the list subject
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    def validate(list)
      if list.list? && list.valid?
        true
      else
        log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
        false
      end
    end
  end
end
