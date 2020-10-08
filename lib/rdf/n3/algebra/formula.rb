require 'rdf/n3'

module RDF::N3::Algebra
  #
  # A Notation3 Formula combines a graph with a BGP query.
  class Formula < SPARQL::Algebra::Operator
    include RDF::Term
    include RDF::Enumerable
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    ##
    # Query to run against a queryable to determine if the formula matches the queryable.
    #
    # @return [RDF::Query]
    attr_accessor :query

    NAME = [:formula]

    ##
    # Create a formula from an RDF::Enumerable (such as RDF::N3::Repository)
    #
    # @param [RDF::Enumerable] enumerable
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @return [RDF::N3::Algebra::Formula]
    def self.from_enumerable(enumerable, **options)
      # SPARQL used for SSE and algebra functionality
      require 'sparql' unless defined?(:SPARQL)

      # Create formulae from statement graph_names
      formulae = {}
      enumerable.graph_names.unshift(nil).each do |graph_name|
        formulae[graph_name] = Formula.new(graph_name: graph_name, formulae: formulae, **options)
      end

      # Add patterns to appropiate formula based on graph_name,
      # and replace subject and object bnodes which identify
      # named graphs with those formula
      enumerable.each_statement do |statement|
        # A graph name indicates a formula.
        graph_name = statement.graph_name
        form = formulae[graph_name]

        # Map statement components to formulae, if necessary.
        statement = RDF::Statement.from(statement.to_a.map do |term|
          case term
          when RDF::Node
            term = if formulae[term]
              # Transform blank nodes denoting formulae into those formulae
              formulae[term]
            elsif graph_name
              # If we're in a quoted graph, transform blank nodes into undistinguished existential variables.
              term.to_ndvar(graph_name)
            else
              term
            end
          when RDF::N3::List
            # Transform blank nodes denoting formulae into those formulae
            term = term.transform {|t| t.node? ? formulae.fetch(t, t) : t}

            # If we're in a quoted graph, transform blank node components into existential variables
            if graph_name && term.has_nodes?
              term = term.to_ndvar(graph_name)
            end
          end
          term
        end)

        pattern = statement.variable? ? RDF::Query::Pattern.from(statement) : statement

        # Formulae may be the subject or object of a known operator
        if klass = RDF::N3::Algebra.for(pattern.predicate)
          form.operands << klass.new(pattern.subject,
                                     pattern.object,
                                     formulae: formulae,
                                     parent: form,
                                     predicate: pattern.predicate,
                                     **options)
        else
          pattern.graph_name = nil
          form.operands << pattern
        end
      end

      # Formula is that without a graph name
      this = formulae[nil]

      # If assigned a graph name, add it here
      this.graph_name = options[:graph_name] if options[:graph_name]
      this
    end

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
            # Replace blank node bindings with lists and formula references with formula, where those blank nodes are associated with lists.
            value = formulae.fetch(value, value) if value.node?
            l = RDF::N3::List.try_list(value, queryable)
            value = l if l.constant?
            memo.merge(name => value)
          end)
        end
        log_info("(formula query solutions)") { SXP::Generator.string(these_solutions.to_sxp_bin)}
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
            log_debug("(formula built-in)") {SXP::Generator.string op.to_sxp_bin}
            solutions = if op.executable?
              op.execute(queryable, solutions: @solutions)
            else # Evaluatable
              @solutions.filter {|s| op.evaluate(s.bindings) == RDF::Literal::TRUE}
            end
            log_debug("(formula intermediate solutions)") {"after #{op.class.const_get(:NAME)}: " + SXP::Generator.string(solutions.to_sxp_bin)}
            # If there are no solutions, try the next one, until we either run out of operations, or we have solutions
            next if solutions.empty?
            last_op = op
            @solutions = RDF::Query::Solutions(solutions)
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
      log_info("(formula sub-op solutions)") {SXP::Generator.string @solutions.to_sxp_bin}

      # Only return solutions with universal variables and distinguished existential variables.
      # FIXME: also filter in-coming existential variables.
      #unless undistinguished_vars.empty?
      #  @solutions = if distinguished_vars.empty?
      #    # No remaining variables, this only an empty solution
      #    RDF::Query::Solutions(RDF::Query::Solution.new)
      #  else
      #    @solutions.dup.project(*distinguished_vars)
      #  end
      #end
      @solutions
    end

    ##
    # Evaluates the formula using the given variable `bindings` by cloning the formula and setting the solutions to `bindings` so that `#each` will generate statements from those bindings.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::N3::List]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, **options)
      this = dup
      this.solutions = RDF::Query::Solutions(bindings)
      this
    end

    ##
    # Returns `true` if `self` is a {RDF::N3::Algebra::Formula}.
    #
    # @return [Boolean]
    def formula?
      true
    end

    ##
    # The formula hash is the hash of it's operands and graph_name.
    #
    # @see RDF::Value#hash
    def hash
      ([graph_name] + operands).hash
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
      log_debug("formula #{graph_name} each") {SXP::Generator.string @solutions.to_sxp_bin}

      # Yield patterns by binding variables
      @solutions.each do |solution|
        # Bind blank nodes to the solution when it doesn't contain a solution for an existential variable
        existential_vars.each do |var|
          solution[var.name] ||= RDF::Node.intern(var.name.to_s.sub(/^\$+/, ''))
        end

        log_debug("(formula apply)") {solution.to_sxp}
        # Yield each variable statement which is constant after applying solution
        patterns.each do |pattern|
          # Skip builtins
          next if RDF::N3::Algebra.for(pattern.predicate)

          terms = {}
          [:subject, :predicate, :object].each do |part|
            terms[part] = case o = pattern.send(part)
            when RDF::Query::Variable
              if solution[o] && solution[o].list?
                solution[o].each_statement(&block)
                # Bind the list subject, and emit list statements
                solution[o].subject
              elsif solution[o] && solution[o].formula?
                form = solution[o]
                # uses the graph_name of the formula, and yields statements from the formula
                form.solutions = RDF::Query::Solutions(solution)
                form.each do |stmt|
                  stmt.graph_name = form.graph_name
                  block.call(stmt)
                end
                form.graph_name
              else
                solution[o]
              end
            when RDF::N3::List
              o.variable? ? o.evaluate(solution.bindings, formulae: formulae) : o
            when RDF::N3::Algebra::Formula
              # uses the graph_name of the formula, and yields statements from the formula
              o.each do |stmt|
                stmt.graph_name = o.graph_name
                block.call(stmt)
              end
              o.graph_name
            else
              o
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

    # Assign a graph name to this formula
    # @param [RDF::Resource] name
    # @return [RDF::Resource]
    def graph_name=(name)
      @options[:graph_name] = name
    end

    ##
    # Statements are the operands
    #
    # @return [Array<RDF::Statement>]
    alias_method :statements, :operands

    ##
    # Patterns memoizer
    #
    # * Patterns exclude builtins.
    # * Blank nodes are replaced with existential variables.
    def patterns
      # BNodes in statements are existential variables.
      @patterns ||= begin
        # Operations/Builtins are not statements.
        operands.
          select {|op| op.is_a?(RDF::Statement) && !RDF::N3::Algebra.for(op.predicate)}.
          map {|st| RDF::Query::Pattern.from(st)}
      end
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
            graph_name && o.has_nodes? ? o.to_ndvar(graph_name) : o
          when RDF::Node
            graph_name ? o.to_ndvar(graph_name) : o
          else
            o
          end
        end
        op
      end
    end

    ##
    # Return the variables contained within this formula
    # @return [Array<RDF::Query::Variable>]
    def vars
      (statements.vars + sub_ops.vars).flatten.compact
    end

    ##
    # Universal vars in this formula and sub-formulae
    # @return [Array<RDF::Query::Variable]
    def universal_vars
      @universals ||= vars.reject(&:existential?).uniq
    end

    ##
    # Existential vars in this formula
    # @return [Array<RDF::Query::Variable]
    def existential_vars
      @existentials ||= vars.select(&:existential?)
    end

    ##
    # Distinguished vars in this formula
    # @return [Array<RDF::Query::Variable]
    def distinguished_vars
      @distinguished ||= vars.vars.select(&:distinguished?)
    end

    ##
    # Undistinguished vars in this formula
    # @return [Array<RDF::Query::Variable]
    def undistinguished_vars
      @undistinguished ||= vars.vars.reject(&:distinguished?)
    end

    def to_s
      to_sxp
    end

    def to_sxp_bin
      [:formula, graph_name].compact +
      operands.map(&:to_sxp_bin)
    end

    def to_base
      inspect
    end

    def inspect
      sprintf("#<%s:%s(%d)>", self.class.name, self.graph_name, self.operands.count)
    end
  end
end
