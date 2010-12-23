$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Reader do
  # W3C Turtle Test suite from http://www.w3.org/2000/10/swap/test/regression.n3
  describe "w3c turtle tests" do
    require 'rdf_helper'

    def self.positive_tests
      RdfHelper::TestCase.test_cases(TURTLE_TEST, TURTLE_DIR)
    end

    def self.negative_tests
      RdfHelper::TestCase.test_cases(TURTLE_BAD_TEST, TURTLE_DIR)
    end

    describe "positive parser tests" do
      positive_tests.each do |t|
        #puts t.inspect
        
        # modified test-10 results to be canonical
        # modified test-21&22 results exponent to be E not e
        # modified test-28 2.30 => 2.3 representation
        specify "#{t.name}: " + (t.description || "#{t.inputDocument} against #{t.outputDocument}") do
          #puts t.inspect
          # Skip tests for very long files, too long
          if !defined?(::Encoding) && %w(test-18).include?(t.name)
            pending("Not supported in Ruby 1.8")
          else
            t.run_test do |rdf_string, parser|
              t.debug = []
              g = RDF::Graph.new
              RDF::Reader.for(t.inputDocument).new(rdf_string,
                  :base_uri => t.about,
                  :strict => true,
                  :canonicalize => true,
                  :debug => t.debug).each do |statement|
                g << statement
              end
              g
            end
          end
        end
      end
    end

    describe "negative parser tests" do
      negative_tests.each do |t|
        #puts t.inspect
        specify "#{t.name}: " + (t.description || t.inputDocument) do
          begin
            t.run_test do |rdf_string, parser|
              lambda do
                t.debug = []
                 g = RDF::Graph.new
                 RDF::Reader.for(t.inputDocument).new(rdf_string,
                     :base_uri => t.about,
                     :strict => true,
                     :debug => t.debug).each do |statement|
                   g << statement
                 end
              end.should raise_error(RDF::ReaderError)
            end
          rescue Spec::Expectations::ExpectationNotMetError => e
            pending() {  raise }
          end
        end
      end
    end
  end

end