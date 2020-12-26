module RDF::N3::Algebra::Log
  ##
  # The subject formula includes the object formula.
  #
  # Formula A includes formula B if there exists some substitution which when applied to B creates a formula B' such that for every statement in B' is also in A, every variable universally (or existentially) quantified in B' is quantified in the same way in A. 
  #
  # Variable substitution is applied recursively to nested compound terms such as formulae, lists and sets.
  #
  # (Understood natively by cwm when in in the antecedent of a rule. You can use this to peer inside nested formulae.)
  class Includes < RDF::N3::Algebra::ResourceOperator
    NAME = :logIncludes
    URI = RDF::N3::Log.includes

    ##
    # Both subject and object must be formulae.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource if resource.formula?
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end

    ##
    # Creates a repository constructed by substituting variables and in that subject with known IRIs and queries object against that repository. Either retuns a single solution, or no solutions.
    #
    # @note this does allow object to have variables not in the subject, if they could have been substituted away.
    #
    # @param  [RDF::N3::Algebra::Formula] subject
    #   a formula
    # @param  [RDF::N3::Algebra::Formula] object
    #   a formula
    # @return [RDF::Literal::Boolean]
    def apply(subject, object)
      subject_var_map = subject.variables.values.inject({}) {|memo, v| memo.merge(v => RDF::URI(v.name))}
      object_vars = object.variables.keys
      log_debug(NAME,  "subject var map") {SXP::Generator.string(subject_var_map.to_sxp_bin)}
      log_debug(NAME, "object vars") {SXP::Generator.string(object_vars.to_sxp_bin)}
      # create a queryable from subject, replacing variables with IRIs for thsoe variables.
      queryable = RDF::Repository.new do |r|
        log_depth do
          subject.each do |stmt|
            parts = stmt.to_quad.map do |part|
              part.is_a?(RDF::Query::Variable) ? subject_var_map.fetch(part) : part
            end
            r << RDF::Statement.from(parts)
          end
        end
      end

      # Query object against subject
      solns = log_depth {queryable.query(object, **@options)}
      log_info("(#{NAME} solutions)") {SXP::Generator.string solns.to_sxp_bin}

      if !solns.empty? && (object_vars - solns.variable_names).empty?
        # Return solution
        solns.first
      else
        # Return false,
        RDF::Literal::FALSE
      end
    end
  end
end
