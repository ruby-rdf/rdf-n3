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
    URI = RDF::N3::Log.implies

    ##
    # Returns solutions from subject. Solutions are created by evaluating subject against `queryable`.
    #
    # Solutions are kept within this instance, and used for conclusions. Note that the evaluated solutions do not affect that of the invoking formula, as the solution spaces are disjoint.
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
        log_debug(NAME, "solution") {SXP::Generator.string(solution.to_sxp_bin)}
        subject = operand(0).evaluate(solution.bindings, formulae: formulae)
        object = operand(1).evaluate(solution.bindings, formulae: formulae)
        log_info(NAME,  "subject") {SXP::Generator.string(subject.to_sxp_bin)}
        log_info(NAME, "object") {SXP::Generator.string(object.to_sxp_bin)}

        # Nothing to do if variables aren't resolved.
        next unless subject && object

        solns = log_depth {subject.execute(queryable, solutions: RDF::Query::Solutions(solution), **options)}

        # Execute object as well (typically used for log:outputString)
        solns.each do |soln|
          log_depth {object.execute(queryable, solutions: RDF::Query::Solutions(soln), **options)}
        end

        # filter solutions where not all variables in antecedant are bound.
        vars = subject.universal_vars
        solns = RDF::Query::Solutions(solns.to_a.select do |soln|
          vars.all? {|v| soln.bound?(v)}
        end)
        solns
      end.flatten.compact.uniq)
      log_info(NAME) {SXP::Generator.string(@solutions.to_sxp_bin)}

      # Return original solutions, without bindings
      solutions
    end

    ##
    # Clear out any cached solutions.
    # This principaly is for log:conclusions
    def clear_solutions
      super
      @solutions = nil
    end

    ##
    # Yields statements from the object based on solutions determined from the subject. Each solution formed by querying `queryable` from the subject is  used to create a graph, which must be a subgraph of `queryable`. If so, that solution is used to generate triples from the object formula which are yielded.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    def each(solutions: RDF::Query::Solutions(), &block)
      # Merge solutions in with those for the evaluation of this implication
      # Clear out solutions so they don't get remembered erroneously.
      solutions, @solutions = Array(@solutions), nil
      log_depth do
        super(solutions: RDF::Query::Solutions(RDF::Query::Solution.new), &block)

        solutions.each do |solution|
          log_info("(logImplies each) solution") {SXP::Generator.string solution.to_sxp_bin}
          object = operand(1).evaluate(solution.bindings, formulae: formulae)
          log_info("(logImplies each) object") {SXP::Generator.string object.to_sxp_bin}

          # Yield inferred statements
          log_depth do
            object.each(solutions: RDF::Query::Solutions(solution)) do |statement|
              log_debug(("(logImplies each) infer\s")) {statement.to_sxp}
              block.call(RDF::Statement.from(statement.to_quad, inferred: true))
            end
          end
        end
      end
    end

    # Graph name associated with this operation, using the name of the parent
    # @return [RDF::Resource]
    def graph_name; parent.graph_name; end
  end
end
