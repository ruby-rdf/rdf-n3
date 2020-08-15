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

  module Queryable
    ##
    # Return the RDF::List representation of the resource from self, with any recursive lists represented as RDF::List.
    #
    # @param [RDF::Resource] subject
    # @return [RDF::List, RDF::Resource] returns either the original resource, or a list based on that resource
    def as_list(subject)
      return subject unless subject.node? || subject.uri? && subject == RDF.nil
      ln = RDF::List.new(subject: subject, graph: self)
      return subject unless ln.valid?

      # Return a new list, outside of this queryable, with any embedded lists also expanded
      RDF::List.new(subject: subject, values: ln.to_a.map {|li| self.as_list(li)})
    end
  end

  class List
    ##
    # Evaluates the list using the given variable `bindings`.
    #
    # @param  [RDF::Query::Solution] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::List]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, **options)
      RDF::List[*to_a.map {|o| o.evaluate(bindings, **options)}]
    end

    ##
    # A list is variable if any of its members are variable?
    #
    # @return [Boolean]
    def variable?
      to_a.any?(&:variable?)
    end

    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      to_a.to_sxp_bin
    end

    ##
    # Returns an S-Expression (SXP) representation
    #
    # @return [String]
    def to_sxp
      to_sxp_bin.to_sxp
    end
  end

  class Statement
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

  module Term
    ##
    # Is this the same term? Like `#eql?`, but no variable matching
    def sameTerm?(other)
      eql?(other)
    end
  end

  class Node
    # Either binds to variable, or returns itself.
    #
    # @param  [RDF::Query::Solution] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Term]
    #     def evaluate(bindings, **options); end
    def evaluate(bindings, **options)
      bindings.fetch(self.id.to_sym, self)
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

  class Query::Variable
    ##
    # True if the other is the same variable
    def sameTerm?(other)
      other.is_a?(::RDF::Query::Variable) && name.eql?(other.name)
    end
  end
end
