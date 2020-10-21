module RDF::N3::Algebra::Log
  ##
  # The subject formula includes the object formula.
  #
  # Formula A includes formula B if there exists some substitution which when applied to B creates a formula B' such that for every statement in B' is also in A, every variable universally (or existentially) quantified in B' is quantified in the same way in A. 
  #
  # Variable substitution is applied recursively to nested compound terms such as formulae, lists and sets.
  #
  # (Understood natively by cwm when in in the antecedent of a rule. You can use this to peer inside nested formulae.)
  class Includes < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    NAME = :logIncludes
    URI = RDF::N3::Log.includes

    ##
    # Creates a repository constructed by evaluating the subject against queryable and queries object against that repository. Either retuns a single solution, or no solutions
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
        subject = operand(0).evaluate(solution.bindings, formulae: formulae)
        object = operand(1).evaluate(solution.bindings, formulae: formulae)
        log_debug(NAME) {"subject: #{SXP::Generator.string subject.to_sxp_bin}"}
        log_debug(NAME) {"object: #{SXP::Generator.string operand(1).to_sxp_bin}"}

        # Nothing to do if variables aren't resolved.
        next unless subject && object

        solns = log_depth {subject.execute(queryable, solutions: RDF::Query::Solutions(solution), **options)}
        log_debug("(logIncludes solutions pre-filter)") {SXP::Generator.string solns.to_sxp_bin}

        # filter solutions where not all variables in antecedant are bound.
        vars = subject.universal_vars
        solns = solns.filter do |solution|
          vars.all? {|v| solution.bound?(v)}
        end
        log_debug("(logIncludes subject)") {SXP::Generator.string solns.to_sxp_bin}
        next if solns.empty?

        repo = RDF::N3::Repository.new << subject

        # Query object against repo
        solns = log_depth {object.execute(repo, solutions: solns, **options)}

        # filter solutions where not all variables in antecedant are bound.
        vars = object.universal_vars
        solns = solns.filter do |soln|
          vars.all? {|v| soln.bound?(v)}
        end
        log_debug("(logIncludes object)") {SXP::Generator.string solns.to_sxp_bin}
        solns
      end.flatten.compact)
    end
  end
end
