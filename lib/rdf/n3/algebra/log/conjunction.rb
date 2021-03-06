module RDF::N3::Algebra::Log
  ##
  # A function to merge formulae: logical AND.
  #
  # The subject is a list of formulae. The object, which can be generated, is a formula containing a copy of each of the formulae in the list on the left. A cwm built-in function.
  class Conjunction < RDF::N3::Algebra::ListOperator
    NAME = :logConjunction
    URI = RDF::N3::Log.conjunction

    ##
    # Evaluates this operator by creating a new formula containing the triples from each of the formulae in the list.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::N3::Algebra::Formula]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      form = RDF::N3::Algebra::Formula.new(graph_name: RDF::Node.intern(list.hash)) 
      log_debug(NAME, "list hash") {form.graph_name}

      list.each do |f|
        form.operands.push(*f.operands)
      end
      form = form.dup
      log_info(NAME, "result") {SXP::Generator.string form.to_sxp_bin}
      form
    end

    ##
    # Return subject operand.
    #
    # @return [RDF::Term]
    def input_operand
      operands.first
    end
  end
end
