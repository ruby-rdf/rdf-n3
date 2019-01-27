# coding: utf-8
module RDF::N3
  ##
  # A Notation-3/Turtle reasoner in Ruby
  #
  # Takes either a parsed formula or an `RDF::Queryable` and updates it by reasoning over formula defined within the queryable.
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Reasoner
    include RDF::Enumerable
    include RDF::Mutable
    include RDF::Util::Logger

    # The top-level parsed formula
    # @return [RDF::N3::Algebra::Formula]
    attr_reader :formula

    # Opens a Notation-3 file, and parses it to initialize the reasoner
    #
    # @param  [String, #to_s] filename
    # @yield  [reasoner] `self`
    # @yieldparam  [RDF::N3::Reasoner] reasoner
    # @yieldreturn [void] ignored
    # @return [RDF::N3::Reasoner]
    def self.open(file)
      RDF::N3::Reader.open(file, **options) do |reader|
        RDF::N3::Reasoner.new(reader, **options, &block)
      end
    end

    ##
    # Initializes a new reasoner. If input is an IO or string, it is taken as n3 source and parsed first. Otherwise, it is a parsed formula.
    #
    # It returns the evaluated formula, or yields triples.
    #
    # @example Initializing from a reader
    #   reader = RDF::N3::Reader.new(":a :b :c .")
    #   reasoner = RDF::N3::Reasoner.new(reader)
    #   reasoner.each_triple {}
    #
    # @example Initializing as a mutable
    #   reasoner = RDF::N3::Reasoner.new do |r|
    #     r << RDF::N3::Reader.new(":a :b :c .")
    #   end
    #   reasoner.each_triple {}
    #
    # @example Initializing with multiple inputs
    #   reasoner = RDF::N3::Reasoner.new
    #   RDF::NTriples::Reader.open("example.nt") {|r| reasoner << r}
    #   RDF::N3::Reader.open("rules.n3") {|r| reasoner << r}
    #   reasoner.each_triple {}
    #
    # @param  [RDF::Enumerable] input (nil)
    # @param  [Hash{Symbol => Object}] options
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @yield  [reasoner] `self`
    # @yieldparam  [RDF::N3::Reasoner] reasoner
    # @yieldreturn [void] ignored
    # @return [RDF::N3::Reasoner]
    def initialize(input, **options, &block)
      @options = options
      @mutable = case input
      when RDF::Mutable then input
      when RDF::Enumerable then RDF::Repository.new {|r| r << input}
      else RDF::Repository.new
      end

      log_debug("reasoner: expression", options) {SXP::Generator.string(formula.to_sxp_bin)}

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
    end

    ##
    # Returns a copy of this reasoner
    def dup
      repo = RDF::Repository.new {|r| r << @mutable}
      self.class.new(repo) do |reasoner|
        reasoner.instance_variable_set(:@options, @options.dup)
        reasoner.instance_variable_set(:@formula, @formula.dup) if @formula
      end
    end

    ##
    # Inserts an RDF statement the datastore, resets `formula`.
    #
    # @param  [RDF::Statement] statement
    # @return [void]
    def insert_statement(statement)
      @mutable.insert_statement(statement)
    end

    ##
    # Updates the datastore by reasoning over the formula, optionally yielding each conclusion; uses triples from the graph associated with this formula as the dataset over which to reason.
    #
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean] :apply
    # @option options [Boolean] :think
    # @yield  [statement]
    # @yieldparam  [RDF::Statement] statement
    # @return [RDF::N3::Reasoner] `self`
    def execute(**options, &block)
      @options[:logger] = options[:logger] if options.has_key?(:logger)

      # If thinking, continuously execute until results stop growing
      if options[:think]
        count = 0
        log_info("reasoner: think start") { "count: #{count}"}
        while @mutable.count > count
          count = @mutable.count
          dataset = RDF::Graph.new << @mutable.project_graph(nil)
          log_depth {formula.execute(dataset, **options)}
          @mutable << formula
        end
        log_info("reasoner: think end") { "count: #{count}"}
      else
        # Run one iteration
        log_info("reasoner: apply start") { "count: #{count}"}
        dataset = RDF::Graph.new << @mutable.project_graph(nil)
        log_depth {formula.execute(dataset, **options)}
        @mutable << formula
        log_info("reasoner: apply end") { "count: #{count}"}
      end

      log_debug("reasoner: datastore") {@mutable.to_sxp}

      conclusions(&block) if block_given?
      self
    end
    alias_method :reason!, :execute

    ##
    # Reason with results in a duplicate datastore
    #
    # @see {execute}
    def reason(**options, &block)
      self.dup.reason!(**options, &block)
    end

    ##
    # Yields each statement in the datastore
    #
    #   @yieldparam  [RDF::Statement] statement
    #   @yieldreturn [void] ignored
    #   @return [void]
    def each(&block)
      @mutable.each(&block)
    end

    ##
    # Yields data, excluding formulae or variables and statements referencing formulae or variables
    #
    # @overload data
    #   @yield  [statement]
    #     each statement
    #   @yieldparam  [RDF::Statement] statement
    #   @yieldreturn [void] ignored
    #   @return [void]
    #
    # @overload data
    #   @return [Enumerator<RDF::Statement>]
    # @return [RDF::Enumerator]
    # @yield  [statement]
    # @yieldparam  [RDF::Statement] statement
    def data(&block)
      if block_given?
        project_graph(nil) do |statement|
          block.call(statement) unless statement.variable? ||
                                      has_graph?(statement.subject) ||
                                      has_graph?(statement.object)
        end
      end
      enum_data
    end
    alias_method :each_datum, :data

    ##
    # Returns an enumerator for {#conclusions}.
    # FIXME: enum_for doesn't seem to be working properly
    # in JRuby 1.7, so specs are marked pending
    #
    # @return [Enumerator<RDF::Statement>]
    # @see    #each_statement
    def enum_data
      # Ensure that statements are queryable, countable and enumerable
      this = self
      RDF::Queryable::Enumerator.new do |yielder|
        this.send(:each_datum) {|y| yielder << y}
      end
    end

    ##
    # Yields conclusions, excluding formulae and those statements in the original dataset, or returns an enumerator over the conclusions
    #
    # @overload conclusions
    #   @yield  [statement]
    #     each statement
    #   @yieldparam  [RDF::Statement] statement
    #   @yieldreturn [void] ignored
    #   @return [void]
    #
    # @overload conclusions
    #   @return [Enumerator<RDF::Statement>]
    # @return [RDF::Enumerator]
    # @yield  [statement]
    # @yieldparam  [RDF::Statement] statement
    def conclusions(&block)
      if block_given?
        # Invoke {#each} in the containing class:
        each_statement {|s| block.call(s) if s.inferred?}
      end
      enum_conclusions
    end
    alias_method :each_conclusion, :conclusions

    ##
    # Returns an enumerator for {#conclusions}.
    # FIXME: enum_for doesn't seem to be working properly
    # in JRuby 1.7, so specs are marked pending
    #
    # @return [Enumerator<RDF::Statement>]
    # @see    #each_statement
    def enum_conclusions
      # Ensure that statements are queryable, countable and enumerable
      this = self
      RDF::Queryable::Enumerator.new do |yielder|
        this.send(:each_conclusion) {|y| yielder << y}
      end
    end

    ##
    # Returns the top-level formula for this file
    #
    # @return [RDF::N3::Algebra::Formula]
    def formula
      # SPARQL used for SSE and algebra functionality
      require 'sparql' unless defined?(:SPARQL)

      @formula ||= begin
        formulae = (@mutable.graph_names.unshift(nil)).inject({}) do |memo, graph_name|
          memo.merge(graph_name => Algebra::Formula.new(graph_name: graph_name, **@options))
        end

        # Add patterns to appropiate formula based on graph_name,
        # and replace subject and object bnodes which identify
        # named graphs with those formula
        @mutable.each_statement do |statement|
          pattern = statement.variable? ? RDF::Query::Pattern.from(statement) : statement

          # A graph name indicates a formula. If not already allocated, create a new formula and use that for inserting statements or other operators
          form = formulae[pattern.graph_name]

          # Formulae may be the subject or object of a known operator
          if klass = Algebra.for(pattern.predicate)
            fs = formulae.fetch(pattern.subject, pattern.subject)
            fo = formulae.fetch(pattern.object, pattern.object)
            form.operands << klass.new(fs, fo, **@options)
          else
            # Add formulae as direct operators
            if formulae.has_key?(pattern.subject)
              form.operands << formulae[pattern.subject]
            end
            if formulae.has_key?(pattern.object)
              form.operands << formulae[pattern.object]
            end
            pattern.graph_name = nil
            form.operands << pattern
          end
        end

        # Order operands in each formula by either the graph_name or subject
        formulae.each_value do |operator|
          next unless operator.is_a?(Algebra::Formula)
          operator.reorder_operands!
        end

        # Formula is that without a graph name
        formulae[nil]
      end
    end

    ##
    # Returns the SPARQL S-Expression (SSE) representation of the parsed formula.
    # Formulae are represented as subjects and objects in the containing graph, along with their universals and existentials
    #
    # @return [Array] `self`
    # @see    http://openjena.org/wiki/SSE
    def to_sxp_bin
      formula.to_sxp_bin
    end
  end
end

