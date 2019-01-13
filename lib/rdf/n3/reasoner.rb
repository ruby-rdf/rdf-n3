# coding: utf-8
module RDF::N3
  ##
  # A Notation-3/Turtle reasoner in Ruby
  #
  # Takes a parsed Notation-3 input and performs reasoning to implement CWM-like interface
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Reasoner
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
        RDF::N3::Reasoner.new(reader.to_sxp_bin, **options, &block)
      end
    end

    ##
    # Initializes a new reasoner. If input is an IO or string, it is taken as n3 source and parsed first. Otherwise, it is a parsed formula.
    #
    # It returns the evaluated formula, or yields triples.
    #
    # @param  [String, IO, StringIO, RDF::N3::Algebra::Formula, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @yield  [reasoner] `self`
    # @yieldparam  [RDF::N3::Reasoner] reasoner
    # @yieldreturn [void] ignored
    # @return [RDF::N3::Reasoner]
    def initialize(input, **options, &block)
      @formula = case input
      when RDF::N3::Algebra::Formula then input
      else RDF::N3::Reader.new(input, **options).formula
      end

      log_debug("reasoner: expression", options) {@formula.to_sxp}

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
    end

    ##
    # Reasons over the formula, yielding each statement
    #
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean] :apply
    # @option options [Boolean] :think
    # @yield  [statement]
    # @yieldparam  [RDF::Statement] statement
    # @return [RDF::Enumerable]
    def execute(**options, &block)
      results = RDF::Graph.new

      # Evaluate once to create initial triples for reasoning
      log_info("reasoner: seed")
      formula.execute(results, **options)
      results << formula

      # If thinking, continuously execute until results stop growing
      if options[:think]
        count = 0
        log_info("reasoner: think start", options) { "count: #{results.count}"}
        while results.count > count
          log_depth {formula.execute(results, **options)}
          results << formula
          count = results.count
        end
        log_info("reasoner: think end") { "count: #{results.count}"}
      else
        # Run one iteration
        log_info("reasoner: apply start") { "count: #{results.count}"}
        log_depth {formula.execute(results, **options)}
        results << formula
        log_info("reasoner: apply end") { "count: #{results.count}"}
      end

      log_debug("reasoner: results") {results.to_sxp}

      results.each(&block) if block_given?
      results
    end
  end
end

