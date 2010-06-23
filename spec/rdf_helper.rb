autoload :YAML, "yaml"
autoload :CGI, 'cgi'

RDFCORE_DIR = File.join(File.dirname(__FILE__), 'rdfcore')
RDFCORE_TEST = "http://www.w3.org/2000/10/rdf-tests/rdfcore/Manifest.rdf"
SWAP_DIR = File.join(File.dirname(__FILE__), 'swap_test')
SWAP_TEST = "http://www.w3.org/2000/10/swap/test/n3parser.tests"
CWM_TEST = "http://www.w3.org/2000/10/swap/test/regression.n3"
TURTLE_DIR = File.join(File.dirname(__FILE__), 'turtle')
TURTLE_TEST = "http://www.w3.org/2001/sw/DataAccess/df1/tests/manifest.ttl"
TURTLE_BAD_TEST = "http://www.w3.org/2001/sw/DataAccess/df1/tests/manifest-bad.ttl"

module RdfHelper
  # Class representing test cases in format http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#

  class TestCase
    class MF < RDF::Vocabulary("http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#"); end
    class QT < RDF::Vocabulary("http://www.w3.org/2001/sw/DataAccess/tests/test-query#"); end
    
    attr_accessor :about
    attr_accessor :approval
    attr_accessor :conclusionDocument
    attr_accessor :data
    attr_accessor :description
    attr_accessor :discussion
    attr_accessor :document
    attr_accessor :entailmentRules
    attr_accessor :inputDocument
    attr_accessor :issue
    attr_accessor :name
    attr_accessor :outputDocument
    attr_accessor :premiseDocument
    attr_accessor :rdf_type
    attr_accessor :status
    attr_accessor :warning
    attr_accessor :parser
    attr_accessor :compare
    attr_accessor :debug
    
    def initialize(statements, uri_prefix, test_dir, options = {})
      statements.each do |statement|
        next if statement.subject.is_a?(RDF::Node)
        pred = statement.predicate.to_s.split(/[\#\/]/).last
        obj  = statement.object.is_a?(RDF::Literal) ? statement.object.value : statement.object.to_s

        puts "#{pred}: #{obj}" if $DEBUG
        if statement.predicate == RDF.type
          self.rdf_type = obj.to_s.split(/[\#\/]/).last
          #puts statement.subject.to_s
        elsif pred =~ /Document\Z/i
          puts "sub #{uri_prefix} in #{obj} for #{test_dir}" if $DEBUG
          about = obj.dup
          obj.sub!(uri_prefix, test_dir)
          puts " => #{obj}" if $DEBUG
          self.send("#{pred}=", obj)
          if pred == "inputDocument"
            self.about ||= about
            self.name ||= statement.subject.to_s.split(/[\#\/]/).last
          end
        elsif pred == "referenceOutput"
          puts "referenceOutput: #{obj}" if $DEBUG
          outputDocument = obj.sub(uri_prefix, test_dir)
          puts "referenceOutput: " + self.send(pred) if $DEBUG
        elsif self.respond_to?("#{pred}=")
          self.send("#{pred}=", obj)
        end
      end
    end

    def inspect
      "[Test Case " + %w(
        about
        name
        inputDocument
        outputDocument
        issue
        status
        approval
        description
        discussion
        issue
        warning
      ).map {|a| v = self.send(a); "#{a}='#{v}'" if v}.compact.join(", ") +
      "]"
    end
    
    # Read in file, and apply modifications reference either .html or .xhtml
    def input
      @input ||= File.read(inputDocument)
    end

    def output
      @output ||= outputDocument && File.read(outputDocument)
    end

    # Run test case, yields input for parser to create triples
    def run_test(options = {})
      rdf_string = input

      # Run
      graph = yield(rdf_string)

      return unless output

      output_graph = RDF::Graph.load(self.outputDocument)
      puts "result: #{CGI.escapeHTML(graph.to_ntriples)}" if $DEBUG
      graph.should Matchers::be_equivalent_graph(output_graph, self)
    end

    def trace
      (@debug || []).to_a.join("\n")
    end
    
    def self.parse_test_cases(test_uri = nil, test_dir = nil)
      raise "Missing test_uri" unless test_uri
      raise "Missing test_dir" unless test_dir
      @test_cases = [] unless test_uri == @test_uri
      return unless @test_cases.empty?

      test = test_uri.to_s.split('/').last
      test_dir = test_dir + "/" unless test_dir.match(%r(/$))
      ext = test.split(".").last
      
      @positive_parser_tests = []
      @negative_parser_tests = []
      @positive_entailment_tests = []
      @negative_entailment_tests = []

      unless File.file?(File.join(test_dir, test.sub(ext, "yml")))
        load_opts = {:base_uri => test_uri}
        load_opts[:format] = :n3 if ext == "tests" # For swap tests
        graph = RDF::Graph.load(File.join(test_dir, test), load_opts)
        uri_base = Addressable::URI.join(test_uri, ".").to_s

        # One of:
        #   http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema
        #   http://www.w3.org/2000/10/swap/test.n3#
        #   http://www.w3.org/2004/11/n3test#
        # Group by subject
        @test_cases = graph.subjects.map do |subj|
          t = TestCase.new(graph.query(:subject => subj), uri_base, test_dir)
          t.name ? t : nil
        end.
          compact.
          sort_by{|t| t.name.to_s}
      else
        # Read tests from Manifest.yml
        self.from_yaml(File.join(test_dir, test.sub(ext, "yml")))
      end

      @test_cases.each do |tc|
        next if tc.status && tc.status != "APPROVED"
        case tc.rdf_type
        when "PositiveParserTest" then @positive_parser_tests << tc
        when "NegativeParserTest" then @negative_parser_tests << tc
        when "PositiveEntailmentTest" then @positive_entailment_tests << tc
        when "NegativeEntailmentTest" then @negative_entailment_tests << tc
        end
      end
    end
    def self.test_cases(test_uri = nil, test_dir = nil);                parse_test_cases(test_uri, test_dir); @test_cases; end
    def self.positive_parser_tests(test_uri = nil, test_dir = nil);     parse_test_cases(test_uri, test_dir); @positive_parser_tests; end
    def self.negative_parser_tests(test_uri = nil, test_dir = nil);     parse_test_cases(test_uri, test_dir); @negative_parser_tests; end
    def self.positive_entailment_tests(test_uri = nil, test_dir = nil); parse_test_cases(test_uri, test_dir); @positive_entailment_tests; end
    def self.negative_entailment_tests(test_uri = nil, test_dir = nil); parse_test_cases(test_uri, test_dir); @negative_entailment_tests; end
    
    def self.to_yaml(test_uri, test_dir, file)
      test_cases = self.test_cases(test_uri, test_dir)
      File.open(file, 'w') do |out|
        YAML.dump(test_cases, out )
      end
    end
    
    def self.from_yaml(file)
      YAML::add_private_type("RdfHelper::TestCase") do |type, val|
        TestCase.new( val )
      end
      File.open(file, 'r') do |input|
        @test_cases = YAML.load(input)
      end
    end
  end
end
