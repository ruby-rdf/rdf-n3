require 'rdf'

module RDF::N3::Algebra
  #
  # A Notation3 Formula combines a graph with a BGP query.
  class Formula < SPARQL::Algebra::Operator
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    attr_accessor :query

    NAME = [:formula]

    ##
    # Yields solutions from patterns and other operands. Solutions are created by evaluating each pattern and other sub-operand against `queryable`.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @option options [RDF::Query::Solutions] solutions
    #   optional initial solutions for chained queries
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    # @return [RDF::Solutions] distinct solutions
    def execute(queryable, **options, &block)
      log_debug {"formula #{graph_name} #{operands.to_sxp}"}

      @query ||= RDF::Query.new(patterns)
      @solutions = queryable.query(@query, **options)

      # Join solutions from other operands
      log_depth do
        sub_ops.each do |op|
          old_solutions, @solutions = @solutions, RDF::Query::Solutions.new
          
          ## XXX consider if this scope introduces new variables with same names
          op.execute(queryable, bindings: old_solutions.bindings) do |soln|
            log_debug {"(formula execute object) => #{soln.inspect}"}
            @solutions << soln
          end
        end
      end
      @solutions.distinct!
      log_debug {"(formula solutions) #{@solutions.inspect}"}
      @solutions
    end

    ##
    # Yields each statement from this formula bound to previously determined solutions.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    def each(&block)
      @solutions ||= begin
        # If there are no solutions, create bindings for all existential variables using the variable name as the bnode identifier
        RDF::Query::Solutions.new(
          [RDF::Query::Solution.new(
            patterns.ndvars.inject({}) {|memo, v| memo.merge(v.name => RDF::Node.intern(v.name))}
          )]
        )
      end
      log_debug {"formula #{graph_name} each #{@solutions.inspect}"}

      # Yield constant statements/patterns
      constants.each do |pattern|
        log_debug {"(formula constant) #{pattern.to_sxp}"}
        block.call(RDF::Statement.from(pattern, graph_name: graph_name))
      end

      # Yield patterns by binding variables
      @solutions.each do |solution|
        log_debug {"(formula apply) #{solution.inspect} to BGP"}
        # Yield each variable statement which is constant after applying solution
        patterns.each do |pattern|
          terms = {}
          [:subject, :predicate, :object].each do |r|
            terms[r] = case o = pattern.send(r)
            when RDF::Query::Variable then solution[o]
            else                           o
            end
          end

          statement = RDF::Statement.from(terms)

          # Sanity checking on statement
          if statement.variable? ||
             statement.predicate.literal? ||
             statement.subject.is_a?(SPARQL::Algebra::Operator) ||
             statement.object.is_a?(SPARQL::Algebra::Operator)
            log_debug {"(formula skip) #{statement.to_sxp}"}
            next
          end

          log_debug {"(formula add) #{statement.to_sxp}"}
          block.call(statement)
        end
      end

      # statements from sub-operands
      log_depth {sub_ops.each {|op| op.each(&block)}}
    end

    # Set solutions
    # @param [RDF::Query::Solutions] solutions
    def solutions=(solutions)
      @solutions = solutions
    end

    # Graph name associated with this formula
    # @return [RDF::Resource]
    def graph_name; @options[:graph_name]; end

    ##
    # Statements memoizer
    def statements
      # BNodes in statements are existential variables
      @statements ||= operands.
        select {|op| op.is_a?(RDF::Statement)}.
        map do |pattern|

        terms = {}
        [:subject, :predicate, :object].each do |r|
          terms[r] = case o = pattern.send(r)
          when RDF::Node then RDF::Query::Variable.new(o.id, distinguished: false)
          else                o
          end
        end

        RDF::Query::Pattern.from(terms)
      end
    end

    ##
    # Constants memoizer
    def constants
      # BNodes in statements are existential variables
      @constants ||= statements.select(&:constant?)
    end

    ##
    # Patterns memoizer
    def patterns
      # BNodes in statements are existential variables
      @patterns ||= statements.reject(&:constant?)
    end

    ##
    # Non-statement operands memoizer
    def sub_ops
      # BNodes in statements are existential variables
      @sub_ops ||= operands.reject {|op| op.is_a?(RDF::Statement)}
    end

    def to_sxp_bin
      @existentials = ndvars.uniq
      @universals = vars.uniq - @existentials
      [:formula, graph_name].compact +
      (Array(universals).empty? ? [] : [universals.unshift(:universals)]) +
      (Array(existentials).empty? ? [] : [existentials.unshift(:existentials)]) +
      operands.map(&:to_sxp_bin)
    end
  end
end
