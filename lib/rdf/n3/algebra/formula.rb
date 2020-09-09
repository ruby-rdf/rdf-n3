require 'rdf/n3'

module RDF::N3::Algebra
  #
  # A Notation3 Formula combines a graph with a BGP query.
  class Formula < SPARQL::Algebra::Operator
    include RDF::Term
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger
    include RDF::N3::Algebra::Builtin

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
      log_info("formula #{graph_name}") {SXP::Generator.string operands.to_sxp_bin}
      log_info("(formula bindings)") { solutions.bindings.map {|k,v| RDF::Query::Variable.new(k,v)}.to_sxp}

      # Only query as patterns if this is an embedded formula
      @query ||= RDF::Query.new(patterns).optimize!
      log_debug("(formula query)") { @query.patterns.to_sxp}

      solutions = if @query.patterns.empty?
        solutions
      else
        these_solutions = queryable.query(@query, solutions: solutions, **options)
        these_solutions.map! do |solution|
          RDF::Query::Solution.new(solution.to_h.inject({}) do |memo, (name, value)|
            # Replace blank node bindings with lists, where those blank nodes are associated with lists.
            l = RDF::N3::List.try_list(value, queryable)
            value = l if l.constant?
            memo.merge(name => value)
          end)
        end
        log_info("(formula query solutions)") { these_solutions.to_sxp}
        solutions.merge(these_solutions)
      end

      # Reject solutions which include variables as values
      @solutions = solutions.dup.filter {|s| s.enum_value.none?(&:variable?)}

      # Use our solutions for sub-ops
      # Join solutions from other operands
      #
      # * Order operands by those having inputs which are constant or bound.
      # * Run built-ins with indeterminant inputs (two-way) until any produces non-empty solutions, and then run remaining built-ins until exhasted or finished.
      # * Re-calculate inputs with bound inputs after each built-in is run.
      log_depth do
        # Iterate over sub_ops using evaluation heuristic
        ops = sub_ops.sort_by {|op| op.rank(@solutions)}
        while !ops.empty?
          last_op = nil
          ops.each do |op|
            log_debug("(formula built-in)") {op.to_sxp}
            solutions = if op.executable?
              op.execute(queryable, solutions: @solutions)
            else # Evaluatable
              @solutions.all? {|s| op.evaluate(s.bindings) == RDF::Literal::TRUE} ?
                @solutions :
                RDF::Query::Solutions.new
            end
            log_debug("(formula intermediate solutions)") {"after #{op.to_sxp}: " + @solutions.to_sxp}
            # If there are no solutions, try the next one, until we either run out of operations, or we have solutions
            next if solutions.empty?
            last_op = op
            @solutions = solutions
            break
          end

          # If there is no last_op, there are no solutions.
          unless last_op
            @solutions = RDF::Query::Solutions.new
            break
          end

          # Remove op from list, and re-order remaining ops.
          ops = (ops - [last_op]).sort_by {|op| op.rank(@solutions)}
        end
      end
      log_info("(formula sub-op solutions)") {@solutions.to_sxp}

      # Only return solutions with universal variables
      variable_names = @solutions.variable_names.reject {|v| v.to_s.start_with?('$')}
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
    # Return the variables contained within this formula
    # @return [Array<RDF::Query::Variable>]
    def vars
      operands.map(&:vars).flatten.compact
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

      # Yield patterns by binding variables
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
            when RDF::Query::Variable
              if solution[o] && solution[o].list?
                solution[o].each_statement(&block)
                # Bind the list subject, and emit list statements
                solution[o].subject
              else
                solution[o]
              end
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
      # BNodes in statements are existential variables.
      @statements ||= begin
        # Operations/Builtins are not statements.
        statements = operands.select {|op| op.is_a?(RDF::Statement) && !RDF::N3::Algebra.for(op.predicate)}

        statements.map do |pattern|
          if graph_name
            terms = {}
            [:subject, :predicate, :object].each do |r|
              terms[r] = case o = pattern.send(r)
              when RDF::N3::List
                # Substitute blank node members with existential variables, recusively.
                o.has_nodes? ? o.to_existential : o
              when RDF::Node
                RDF::Query::Variable.new(o.id, existential: true)
              else
                o
              end
            end

            # A pattern with a non-destinguished variable becomes optional, so that it will bind to itself, if not matched in queryable.
            RDF::Query::Pattern.from(terms)
          else
            RDF::Query::Pattern.from(pattern)
          end
        end
      end
    end

    ##
    # Patterns memoizer
    def patterns
      # BNodes in statements are existential variables
      @patterns ||= statements
    end

    ##
    # Non-statement operands memoizer
    def sub_ops
      # operands that aren't statements, ordered by their graph_name
      @sub_ops ||= operands.reject {|op| op.is_a?(RDF::Statement)}.map do |op|
        # Substitute nodes for existential variables in operator operands
        op.operands.map! do |o|
          case o
          when RDF::N3::List
            # Substitute blank node members with existential variables, recusively.
            o.has_nodes? ? o.to_existential : o
          when RDF::Node
            RDF::Query::Variable.new(o.id, existential: true)
          else
            o
          end
        end
        op
      end
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

    def to_s
      to_sxp
    end

    def to_sxp_bin
      raise "a formula can't contain itself" if operands.include?(self)
      [:formula, graph_name].compact +
      operands.map(&:to_sxp_bin)
    end
  end
end
