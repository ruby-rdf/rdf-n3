require 'rdf/n3'

module RDF::N3::Algebra
  ##
  # Behavior for N3 builtin operators
  module Builtin
    include RDF::Enumerable
    include RDF::Util::Logger

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

    ##
    # By default, operators do not yield statements
    def each(&block)
    end

    ##
    # The builtin hash is the hash of it's operands and NAME.
    #
    # @see RDF::Value#hash
    def hash
      ([self.class.const_get(:NAME)] + operands).hash
    end

    # The URI of this operator.
    def to_uri
      Kernel.const_get('::' + self.class.to_s.split('::')[0..-2].join('::')).vocab + self.class.const_get(:NAME)
    end
  end
end
