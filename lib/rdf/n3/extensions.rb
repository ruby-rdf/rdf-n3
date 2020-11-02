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
      [(variable? ? :pattern : (has_graph? ? :quad : :triple)), subject, predicate, object, graph_name].compact
    end

    ##
    # Returns an S-Expression (SXP) representation
    #
    # @return [String]
    def to_sxp
      to_sxp_bin.to_sxp
    end

    ##
    # As a statement is constant, this returns itself.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Statement]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      self
    end
  end

  module Value
    ##
    # Returns `true` if `self` is a {RDF::N3::Algebra::Formula}.
    #
    # @return [Boolean]
    def formula?
      false
    end

    # By default, returns itself. Can be used for terms such as blank nodes to be turned into non-disinguished variables.
    #
    # @param [RDF::Node] scope
    # return [RDF::Query::Variable]
    def to_ndvar(scope)
      self
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

    ##
    # Parse the value as a dateTime literal, or return now.
    #
    # @return [RDF::Literal::DateTime]
    def as_datetime
      RDF::Literal::DateTime.new(DateTime.now)
    end

    ##
    # As a term is constant, this returns itself.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Term]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      self
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

    ##
    # Parse the value as a dateTime literal, or return now.
    #
    # @return [RDF::Literal::DateTime]
    def as_datetime
      return self if is_a?(RDF::Literal::DateTime)
      mvalue = value
      mvalue = "#{mvalue}-01" if mvalue.match?(%r(^\d{4}$))
      mvalue = "#{mvalue}-01" if mvalue.match?(%r(^\d{4}-\d{2}$))
      RDF::Literal::DateTime.new(::DateTime.iso8601(mvalue), lexical: value)
    rescue
      RDF::Literal(0)
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
    # Transform to a nondistinguished exisetntial variable in a formula scope
    #
    # @param [RDF::Node] scope
    # return [RDF::Query::Variable]
    def to_ndvar(scope)
      label = "#{id}_#{scope ? scope.id : 'base'}_undext"
      RDF::Query::Variable.new(label, existential: true, distinguished: false)
    end

    ##
    # Blank node may refer to a formula.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Term]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      node? ? formulae.fetch(self, self) : self
    end
  end

  class Query::Pattern
    ##
    # Overrides `#initialize!` to turn blank nodes into non-distinguished variables, if the `:ndvars` option is set.
    alias_method :orig_initialize!, :initialize!
    def initialize!
      if @options[:ndvars]
        @graph_name = @graph_name.to_ndvar(nil) if @graph_name
        @subject = @subject.to_ndvar(@graph_name)
        @predicate = @predicate.to_ndvar(@graph_name)
        @object = @object.to_ndvar(@graph_name)
      end
      orig_initialize!
    end

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

    ##
    # Evaluates the pattern using the given variable `bindings` by cloning the pattern replacing variables with their bindings recursively. If the resulting pattern is constant, it is cast as a statement.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Statement]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      elements = self.to_quad.map do |term|
        term.evaluate(bindings, formulae: formulae, **options)
      end.compact.map do |term|
        term.node? ? formulae.fetch(term, term) : term
      end

      self.class.from(elements)
    end
  end

  class Query::Solution
    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      [:solution] + bindings.map do |k, v|
        existential = k.to_s.end_with?('ext')
        k = k.to_s.sub(/_(?:und)?ext$/, '').to_sym
        distinguished = !k.to_s.end_with?('undext')
        Query::Variable.new(k, v, existential: existential, distinguished: distinguished).to_sxp_bin
      end
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
      to_s
    end

    ##
    # If variable is bound, replace with the bound value, otherwise, returns itself
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Term]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      value = bindings.has_key?(name) ? bindings[name] : self
      value.node? ? formulae.fetch(value, value) : value
    end
  end

  class SPARQL::Algebra::Operator
    ##
    # Map of related formulae, indexed by graph name.
    #
    # @return [Hash{RDF::Resource => RDF::N3::Algebra::Formula}]
    def formulae
      @options.fetch(:formulae, {})
    end

    # Updates the operands for this operator.
    #
    # @param [Array] ary
    # @return [Array]
    def operands=(ary)
      @operands = ary
    end
  end
end
