module RDF::N3::Algebra::Log
  ##
  # Logical implication.
  #
  # This is the relation between the antecedent (subject) and conclusion (object) of a rule. The application of a rule to a knowledge-base is as follows. For every substitution which, applied to the antecedent, gives a formula which is a subset of the knowledge-base, then the result of applying that same substitution to the conclusion may be added to the knowledge-base.
  #
  # related: See log:conclusion.
  class Implies < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    NAME = :logImplies

    ##
    # Returns solutions from subject. Solutions are created by evaluating subject against `queryable`.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @option options [RDF::Query::Solutions] solutions
    #   optional initial solutions for chained queries
    # @return [RDF::Solutions] distinct solutions
    def execute(queryable, solutions:, **options)
      @queryable = queryable
      @solutions = RDF::Query::Solutions(solutions.map do |solution|
        subject = operand(0).evaluate(solution.bindings)
        object = operand(1).evaluate(solution.bindings)
        log_debug(NAME) {"subject: #{SXP::Generator.string subject.to_sxp_bin}"}
        log_debug(NAME) {"object: #{SXP::Generator.string operand(1).to_sxp_bin}"}

        # Nothing to do if variables aren't resolved.
        next unless subject && object

        solns = log_depth {subject.execute(queryable, solutions: RDF::Query::Solutions(solution), **options)}
        log_debug("(logImplies solutions pre-filter)") {SXP::Generator.string solns.to_sxp_bin}

        # filter solutions where not all variables in antecedant are bound.
        vars = subject.universal_vars
        solns = solns.filter do |soln|
          vars.all? {|v| soln.bound?(v)}
        end
        log_info("(logImplies solutions)") {SXP::Generator.string solns.to_sxp_bin}
        solns
      end.flatten.compact)

      # Return original solutions, without bindings
      solutions
    end

    ##
    # Yields statements from the object based on solutions determined from the subject. Each solution formed by querying `queryable` from the subject is  used to create a graph, which must be a subgraph of `queryable`. If so, that solution is used to generate triples from the object formula which are yielded.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    def each(&block)
      @solutions ||= RDF::Query::Solutions.new
      log_debug {"logImplies each #{SXP::Generator.string @solutions.to_sxp_bin}"}

      log_depth do
        @solutions.each do |solution|
          object = operand(1).evaluate(solution.bindings)
          next unless object # shouldn't happen

          object.solutions = RDF::Query::Solutions(solution)

          # Yield statements into the default graph
          object.each do |statement|
            block.call(RDF::Statement.from(statement.to_quad, inferred: true))
          end
        end
      end
    end

    # Graph name associated with this operation, using the name of the parent
    # @return [RDF::Resource]
    def graph_name; parent.graph_name; end
  end
end
