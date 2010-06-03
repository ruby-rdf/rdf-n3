require 'matchers'

module SWAPHelper
  # Class representing test cases in format http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#
  class TestCase
    include Matchers
    
    TEST_DIR = File.join(File.dirname(__FILE__), 'swap_test')
    
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
    
    @@test_cases = []
    
    def initialize(triples)
      triples.each do |statement|
        next if statement.subject.is_a?(BNode)
#        self.about ||= statement.subject
#        self.name ||= statement.subject.short_name
        
        if statement.is_type?
          self.rdf_type = statement.object.short_name
        elsif statement.predicate.short_name =~ /Document\Z/i
          #puts "#{statement.predicate.short_name}: #{statement.object.inspect}"
          self.send("#{statement.predicate.short_name}=", statement.object.to_s.sub(/^.*swap\/test/, TEST_DIR))
          if statement.predicate.short_name == "inputDocument"
            self.about ||= statement.object
            self.name ||= statement.object.short_name
          end
        elsif self.respond_to?("#{statement.predicate.short_name}=")
          self.send("#{statement.predicate.short_name}=", statement.object.to_s)
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
    
    def compare; :graph; end
    
    # Read in file, and apply modifications reference either .html or .xhtml
    def input
      File.read(inputDocument)
    end

    def output
      outputDocument && File.read(outputDocument)
    end

    # Run test case, yields input for parser to create triples
    def run_test
      rdf_string = input

      # Run
      @parser = RdfXmlParser.new
      yield(rdf_string, @parser)

      @parser.graph.should be_equivalent_graph(output, self) if output
    end

    def trace
      @parser.debug.to_a.join("\n")
    end
    
    def self.parse_test_cases
      return unless @@test_cases.empty?
      
      @@positive_parser_tests = []
      @@negative_parser_tests = []
      @@positive_entailment_tests = []
      @@negative_entailment_tests = []

      manifest = File.read(File.join(TEST_DIR, "n3parser.tests"))
      parser = Parser.new
      begin
        parser.parse(manifest, "http://www.w3.org/2000/10/swap/test/n3parser.tests")
      rescue
        raise "Parse error: #{$!}\n\t#{parser.debug.join("\t\n")}\n\n"
      end
      graph = parser.graph
      
      # Group by subject
      test_hash = graph.triples.inject({}) do |hash, st|
        a = hash[st.subject] ||= []
        a << st
        hash
      end
      
      @@test_cases = test_hash.values.map {|statements| TestCase.new(statements)}.compact.sort_by{|t| t.about.is_a?(URIRef) ? t.about.uri.to_s : "zzz"}
      
      @@test_cases.each do |tc|
        next unless tc.status == "APPROVED"
        case tc.rdf_type
        when "PositiveParserTest" then @@positive_parser_tests << tc
        when "NegativeParserTest" then @@negative_parser_tests << tc
        when "PositiveEntailmentTest" then @@positive_entailment_tests << tc
        when "NegativeEntailmentTest" then @@negative_entailment_tests << tc
        end
      end
    end
    def self.test_cases;                parse_test_cases; @@test_cases; end
    def self.positive_parser_tests;     parse_test_cases; @@positive_parser_tests; end
    def self.negative_parser_tests;     parse_test_cases; @@negative_parser_tests; end
    def self.positive_entailment_tests; parse_test_cases; @@positive_entailment_tests; end
    def self.negative_entailment_tests; parse_test_cases; @@negative_entailment_tests; end
  end
end
