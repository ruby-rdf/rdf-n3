module RDF::N3::Algebra::Log
  ##
  # A function to merge formulae: logical AND.
  #
  # The subject is a list of formulae. The object, which can be generated, is a formula containing a copy of each of the formulae in the list on the left. A cwm built-in function.
  class Conjunction < RDF::N3::Algebra::ListOperator
    include RDF::N3::Algebra::Builtin

    NAME = :logConjunction

    ##
    # Evaluates this operator by creating a new formula containing the triples from each of the formulae in the list.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::N3::Algebra::Formula]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      form = RDF::N3::Algebra::Formula.new(graph_name: RDF::Node.intern(list.hash)) 

      list.each do |f|
        form.operands.append(*f.operands)
      end
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
