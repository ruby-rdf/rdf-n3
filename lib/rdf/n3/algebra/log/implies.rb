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

    # Yields solutions from subject. Solutions are created by evaluating subject against `queryable`.
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
      log_debug {"logImplies"}
      @solutions = log_depth {operands.first.execute(queryable, solutions: solutions, **options)}
      log_debug("(logImplies solutions pre-filter)") {SXP::Generator.string @solutions.to_sxp_bin}

      # filter solutions where not all variables in antecedant are bound.
      vars = operands.first.universal_vars
      @solutions = @solutions.filter do |solution|
        vars.all? {|v| solution.bound?(v)}
      end
      log_debug("(logImplies solutions)") {SXP::Generator.string @solutions.to_sxp_bin}

      # Return original solutions, without bindings
      solutions
    end

    ##
    # Input is the subject
    #
    # @return [RDF::Term]
    def input_operand
      # By default, return the merger of input and output operands
      operand(0)
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
      subject, object = operands

      return if @solutions.empty?

      log_debug {"logImplies each #{SXP::Generator.string @solutions.to_sxp_bin}"}

      # Use solutions from subject for object
      object.solutions = @solutions

      # Nothing emitted if @solutions is not complete. Solutions are complete when all variables are bound.
      log_info("(logImplies implication true; solutions: #{SXP::Generator.string @solutions.to_sxp_bin})")
      # Yield statements into the default graph
      log_depth do
        object.each do |statement|
          block.call(RDF::Statement.from(statement.to_quad, inferred: true))
        end
      end
    end

    # Graph name associated with this operation, using the name of the parent
    # @return [RDF::Resource]
    def graph_name; parent.graph_name; end
  end
end
