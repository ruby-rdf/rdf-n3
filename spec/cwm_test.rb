# Spira class for manipulating test-manifest style test suites.
# Used for SWAP tests
require 'spira'
require 'rdf/n3'
require 'open-uri'
require 'matchers'

module Fixtures
  module Cwm
    class SWAP < RDF::Vocabulary("http://www.w3.org/2000/10/swap/test.n3#"); end

    class CwmTest
      attr_accessor :debug
      attr_accessor :compare
      include Spira::Resource

      default_source :cwm

      type SWAP.CwmTest
      property :description, :predicate => SWAP.description, :type => XSD.string
      property :referenceOutput, :predicate => SWAP.referenceOutput
      property :arguments, :predicate => SWAP.arguments, :type => XSD.string

      def inputDocument
        self.arguments if self.arguments.match(/\w+[^\s]*.n3$/)
      end
      
      def name
        subject.to_s.split("#").last
      end

      def input
        Kernel.open(self.inputDocument)
      end
      
      def reference
        self.referenceOutput ? Kernel.open(self.referenceOutput) : ""
      end

      def information; self.description; end
      
      def inspect
        "[#{self.class.to_s} " + %w(
          subject
          description
          inputDocument
          referenceOutput
        ).map {|a| v = self.send(a); "#{a}='#{v}'" if v}.compact.join(", ") +
        "]"
      end

      # Run test case, yields input for parser to create triples
      def run_test(options = {})
        # Run
        graph = yield
        
        return unless self.outputDocument

        case self.compare
        when :none
          # Don't check output, just parse to graph
        when :array
          @parser.graph.should be_equivalent_graph(self.output, self)
        else
          #puts "parse #{self.outputDocument} as #{RDF::Reader.for(self.outputDocument)}"
          format = detect_format(self.reference)
          output_graph = RDF::Graph.load(self.referenceOutput, :format => format, :base_uri => self.subject)
          puts "result: #{CGI.escapeHTML(graph.dump(:ntriples))}" if ::RDF::N3::debug?
          graph.should Matchers::be_equivalent_graph(output_graph, self)
        end
      end
    end

    repo = RDF::Repository.load("http://www.w3.org/2000/10/swap/test/regression.n3", :format => :n3)
    Spira.add_repository! :cwm, repo
  end
end