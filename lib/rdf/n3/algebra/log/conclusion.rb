module RDF::N3::Algebra::Log
  ##
  # All possible conclusions which can be drawn from a formula.
  #
  # The object of this function, a formula, is the set of conclusions which can be drawn from the subject formula, by successively applying any rules it contains to the data it contains. This is equivalent to cwm's "--think" command line function.  It does use built-ins, so it may for example indirectly invoke other documents, validate signatures, etc.
  class Conclusion < RDF::N3::Algebra::ResourceOperator
    NAME = :logConclusion
    URI = RDF::N3::Log.conclusion

    ##
    # Evaluates this operator by creating a new formula containing the triples generated by reasoning over the input formula using think.
    #
    # The subject is evaluated into an isolated repository so that conclusions evaluated when evaluating the subject are not necessarily conclusions resulting from evaluating this operator.
    #
    # @param [RDF::N3::Algebra:Formula] resource
    # @return [RDF::N3::Algebra::Formula]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(resource, position:)
      return resource unless position == :subject

      log_depth do
        reasoner = RDF::N3::Reasoner.new(resource, **@options)
        conclusions = RDF::N3::Repository.new
        reasoner.execute(think: true) {|stmt| conclusions << stmt}

        # The result is a formula containing the conclusions
        form = RDF::N3::Algebra::Formula.from_enumerable(conclusions, **@options).deep_dup

        log_info("#{NAME} resolved") {SXP::Generator.string form.to_sxp_bin} 
        form
      end
    end

    ##
    # To be valid, subject must be a formula, and object a formula or variable.
    #
    # @param [RDF::Term] subject
    # @param [RDF::Term] object
    # @return [Boolean]
    def valid?(subject, object)
      subject.formula? && (object.formula? || object.is_a?(RDF::Query::Variable))
    end

    ##
    # Return subject operand.
    #
    # @return [RDF::Term]
    def input_operand
      operands.first
    end

    ##
    # Yields statements, and de-asserts `inferred` from the subject.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    def each(solutions:, &block)
      super do |stmt|
        block.call(RDF::Statement.from(stmt.to_quad))
      end
    end
  end
end