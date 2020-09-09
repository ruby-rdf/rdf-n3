require 'rdf/n3'

module RDF::N3::Algebra
  ##
  # Behavior for N3 builtin operators
  module Builtin
    ##
    # Determine ordering for running built-in operator considering if subject or object is varaible and considered an input or an output. Accepts a solution set to determine if variable inputs are bound.
    #
    # @param [RDF::Query::Solutions] solutions
    # @return [Integer] rake for ordering, lower numbers have fewer unbound output variables.
    def rank(solutions)
      vars = input_operand.vars - solutions.variable_names
      # The rank is the remaining unbound variables
      vars.count
    end

    ##
    # Return subject or object operand, or both, depending on which is considered an input.
    #
    # @return [RDF::Term]
    def input_operand
      # By default, return the merger of input and output operands
      RDF::N3::List.new(values: operands)
    end
  end
end
