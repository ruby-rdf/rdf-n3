# frozen_string_literal: true
require 'rdf'
require 'rdf/n3/terminals'

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

  class List
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
      to_a.to_sxp_bin.to_sxp
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

  module Value
    ##
    # Returns `true` if `self` is a {RDF::N3::Formula}.
    #
    # @return [Boolean]
    def formula?
      false
    end
  end

  module Term
    ##
    # Is this the same term? Like `#eql?`, but no variable matching
    def sameTerm?(other)
      eql?(other)
    end

    ##
    # Parse the value as a numeric literal, or return 0.
    #
    # @return [RDF::Literal::Numeric]
    def as_number
      RDF::Literal(0)
    end
  end

  class Literal
    include RDF::N3::Terminals

    ##
    # Parse the value as a numeric literal, or return 0.
    #
    # @return [RDF::Literal::Numeric]
    def as_number
      return self if self.is_a?(RDF::Literal::Numeric)
      case value
      when DOUBLE  then RDF::Literal::Double.new(value)
      when DECIMAL then RDF::Literal::Decimal.new(value)
      when INTEGER then RDF::Literal::Integer.new(value)
      else
        RDF::Literal(0)
      end
    end

    class Double
      ##
      # Returns the SXP representation of this object.
      #
      # @return [String]
      def to_sxp
        case
          when nan? then 'nan.0'
          when infinite? then (infinite? > 0 ? '+inf.0' : '-inf.0')
          else canonicalize.to_s.downcase
        end
      end
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

  class Query::Pattern
    ##
    # Checks pattern equality against a statement, considering nesting an lists.
    #
    # * A pattern which has a pattern as a subject or an object, matches
    #   a statement having a statement as a subject or an object using {#eql?}.
    #
    # @param  [Statement] other
    # @return [Boolean]
    #
    # @see RDF::URI#==
    # @see RDF::Node#==
    # @see RDF::Literal#==
    # @see RDF::Query::Variable#==
    def eql?(other)
      return false unless other.is_a?(RDF::Statement) && (self.graph_name || false) == (other.graph_name || false)

      [:subject, :predicate, :object].each do |part|
        case o = self.send(part)
        when RDF::Query::Pattern, RDF::List
          return false unless o.eql?(other.send(part))
        else
          return false unless o == other.send(part)
        end
      end
      true
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

    ##
    # Parse the value as a numeric literal, or return 0.
    #
    # @return [RDF::Literal::Numeric]
    def as_number
      RDF::Literal(0)
    end

    def to_sxp
      prefix = distinguished? ? (existential? ? '$' : '?') : (existential? ? '$$' : '??')
      unbound? ? "#{prefix}#{name}" : "#{prefix}#{name}=#{value.to_sxp}"
    end
  end
end
