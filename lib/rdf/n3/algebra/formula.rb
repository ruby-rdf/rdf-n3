require 'rdf'

module RDF::N3::Algebra
  #
  # A Notation3 Formula combines a graph with a BGP query.
  class Formula < SPARQL::Algebra::Operator
    include RDF::Term
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    attr_accessor :query

    NAME = [:formula]

    ##
    # Yields solutions from patterns and other operands. Solutions are created by evaluating each pattern and other sub-operand against `queryable`.
    #
    # When executing, blank nodes are turned into non-distinguished existential variables, noted with `$$`. These variables are removed from the returned solutions, as they can't be bound outside of the formula.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @option options [RDF::Query::Solutions] solutions
    #   optional initial solutions for chained queries
    # @return [RDF::Solutions] distinct solutions
    def execute(queryable, solutions: RDF::Query::Solutions(RDF::Query::Solution.new), **options)
      log_debug("formula #{graph_name}") {operands.to_sxp}
      log_debug("(formula bindings)") { solutions.bindings.map {|k,v| RDF::Query::Variable.new(k,v)}.to_sxp}

      # Only query as patterns if this is an embedded formula
      @query ||= RDF::Query.new(patterns).optimize!

      @solutions = if @query.patterns.empty?
        solutions
      else
        these_solutions = queryable.query(@query, solutions: solutions, **options)
        these_solutions.map! do |solution|
          RDF::Query::Solution.new(solution.to_h.inject({}) do |memo, (name, value)|
            # Replace blank node bindings with lists, where those blank nodes are associated with lists
            l = queryable.as_list(value) unless value.list?
            value = l if l
            memo.merge(name => value)
          end)
        end
        solutions.merge(these_solutions)
      end

      # Reject solutions which include variables as values
      @solutions = @solutions.filter {|s| s.enum_value.none?(&:variable?)}

      # Use our solutions for sub-ops
      # Join solutions from other operands
      log_depth do
        sub_ops.each do |op|
          @solutions = if op.executable?
            op.execute(queryable, solutions: @solutions)
          else
            op.evaluate(@solutions.bindings) == RDF::Literal::TRUE ? @solutions : RDF::Query::Solutions.new
          end
        end
      end
      log_debug("(formula solutions)") {@solutions.to_sxp}

      # Only return solutions with distinguished variables
      variable_names = @solutions.variable_names.reject {|v| v.to_s.start_with?('$$')}
      variable_names.empty? ? @solutions : @solutions.dup.project(*variable_names)
    end

    ##
    # Returns `true` if `self` is a {RDF::N3::Formula}.
    #
    # @return [Boolean]
    def formula?
      true
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
        # If there are no solutions, create a single solution
        RDF::Query::Solutions(RDF::Query::Solution.new)
      end
      log_debug("formula #{graph_name} each") {@solutions.to_sxp}

      # Yield constant statements/patterns
      constants.each do |pattern|
        #log_debug {"(formula constant) #{pattern.to_sxp}"}
        block.call(RDF::Statement.from(pattern, graph_name: graph_name))
      end

      # Yield patterns by binding variables
      # FIXME: do we need to do something with non-bound non-distinguished extistential variables?
      @solutions.each do |solution|
        # Bind blank nodes to the solution when it doesn't contain a solution for an existential variable
        existential_vars.each do |var|
          solution[var.name] ||= RDF::Node.intern(var.name.to_s.sub(/^\$+/, ''))
        end

        log_debug("(formula apply)") {solution.to_sxp}
        # Yield each variable statement which is constant after applying solution
        patterns.each do |pattern|
          terms = {}
          [:subject, :predicate, :object].each do |part|
            terms[part] = case o = pattern.send(part)
            when RDF::Query::Variable then solution[o]
            else                           o
            end
          end

          statement = RDF::Statement.from(terms)

          # Sanity checking on statement
          if statement.variable?
            log_debug("(formula skip)") {statement.to_sxp}
            next
          end

          #log_debug("(formula add)") {statement.to_sxp}
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
      # BNodes in statements are non-distinguished existential variables
      @statements ||= operands.
        select {|op| op.is_a?(RDF::Statement)}.
        map do |pattern|

        # Map nodes to non-distinguished existential variables (except when in top-level formula)
        if graph_name
          terms = {}
          [:subject, :predicate, :object].each do |r|
            terms[r] = case o = pattern.send(r)
            when RDF::Node then RDF::Query::Variable.new(o.id, existential: true, distinguished: false)
            else                o
            end
          end

          RDF::Query::Pattern.from(terms)
        else
          RDF::Query::Pattern.from(pattern)
        end
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
      # operands that aren't statements, ordered by their graph_name
      @sub_ops ||= operands.reject {|op| op.is_a?(RDF::Statement)}
    end

    ##
    # Universal vars in this formula and sub-formulae
    def universal_vars
      @universals ||= (patterns.vars + sub_ops.vars).reject(&:existential?).uniq
    end

    ##
    # Existential vars in this formula
    def existential_vars
      @existentials ||= patterns.vars.select(&:existential?)
    end

    def to_sxp_bin
      raise "a formula can't contain itself" if operands.include?(self)
      [:formula, graph_name].compact +
      operands.map(&:to_sxp_bin)
    end
  end
end
