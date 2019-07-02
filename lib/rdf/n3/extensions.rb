# frozen_string_literal: true
require 'rdf'

# Monkey-patch RDF::Enumerable to add `:existentials` and `:univerals` accessors
module RDF
  module Enumerable
    # Existential quantifiers defined on this enumerable
    # @return [Array<RDF::Query::Variable>]
    attr_accessor :existentials

    # Universal quantifiers defined on this enumerable
    # @return [Array<RDF::Query::Variable>]
    attr_accessor :universals

    ##
    # An enumerable contains another enumerable if every statement in other is a statement in self
    #
    # @param [RDF::Enumerable] other
    # @return [Boolean]
    def contain?(other)
      other.all? {|statement| has_statement?(statement)}
    end
  end

  class Statement
    # Override variable?
    def variable?
      to_a.any? {|term| !term.is_a?(RDF::Term) || term.variable?} || graph_name && graph_name.variable?
    end

    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      [(variable? ? :pattern : :triple), subject, predicate, object, graph_name].compact
    end

    ##
    # Returns an S-Expression (SXP) representation
    #
    # @return [String]
    def to_sxp
      to_sxp_bin.to_sxp
    end
  end

  class Query::Solution

    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      [:solution] + bindings.map {|k, v| Query::Variable.new(k, v).to_sxp_bin}
    end

    ##
    # Returns an S-Expression (SXP) representation
    #
    # @return [String]
    def to_sxp
      to_sxp_bin.to_sxp
    end
  end
end
