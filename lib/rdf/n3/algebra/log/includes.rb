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
      subject = subject.evaluate(solutions.first.bindings) || operand(0)
      object = object.evaluate(solutions.first.bindings) || operand(1)
      log_debug(self.class.const_get(:NAME)) {"subject: #{SXP::Generator.string subject.to_sxp_bin}"}
      log_debug(self.class.const_get(:NAME)) {"object: #{SXP::Generator.string object.to_sxp_bin}"}

      # Nothing to do if variables aren't resolved.
      return @solutions = solutions if subject.is_a?(RDF::Query::Variable) || object.is_a?(RDF::Query::Variable)

      solutions = log_depth {subject.execute(queryable, solutions: solutions, **options)}
      log_debug("(logImplies solutions pre-filter)") {SXP::Generator.string solutions.to_sxp_bin}

      # filter solutions where not all variables in antecedant are bound.
      vars = subject.universal_vars
      solutions = solutions.filter do |solution|
        vars.all? {|v| solution.bound?(v)}
      end
      log_debug("(#{self.class.const_get(:NAME)} solutions(0))") {SXP::Generator.string solutions.to_sxp_bin}
      return @solutions = solutions if solutions.empty?

      repo = RDF::N3::Repository.new << subject

      # Query object against repo
      solutions = log_depth {object.execute(repo, solutions: solutions, **options)}

      # filter solutions where not all variables in antecedant are bound.
      vars = object.universal_vars
      @solutions = solutions.filter do |solution|
        vars.all? {|v| solution.bound?(v)}
      end
      log_debug("(#{self.class.const_get(:NAME)} solutions(1))") {SXP::Generator.string @solutions.to_sxp_bin}
      # Return original solutions, without bindings
      @solutions
    end

    ##
    # Both subject and object are inputs
    #
    # @return [RDF::Term]
    def input_operand
      RDF::N3::List.new(values: operands)
    end
  end
end
