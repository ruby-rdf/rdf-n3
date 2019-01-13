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
  end

  class Statement
    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      [(variable? ? :pattern : :triple), subject, predicate, object]
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
