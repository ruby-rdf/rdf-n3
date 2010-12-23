$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c swap tests" do
    require 'rdf_helper'

    def self.positive_tests
      RdfHelper::TestCase.positive_parser_tests(SWAP_TEST, SWAP_DIR)
    end

    def self.negative_tests
      RdfHelper::TestCase.negative_parser_tests(SWAP_TEST, SWAP_DIR)
    end

    # Negative parser tests should raise errors.
    describe "positive parser tests" do
      positive_tests.each do |t|
        #next unless t.about.uri.to_s =~ /rdfms-rdf-names-use/
        #next unless t.name =~ /11/
        #puts t.inspect
        specify "#{t.name}: #{t.about} against #{t.outputDocument}" do
          begin
            t.run_test do |rdf_string|
              t.name.should_not == "n3_10012"  # Too many bnodes makes graph compare unfeasable
              t.debug = []
              g = RDF::Graph.new
              RDF::N3::Reader.new(rdf_string,
                  :base_uri => t.about,
                  :strict => true,
                  :debug => t.debug).each do |statement|
                g << statement
              end
              g
            end
          rescue #Spec::Expectations::ExpectationNotMetError => e
            if %w(n3_10012).include?(t.name)
              pending("check visually, graph compare times too long")
            elsif %w(n3_10010).include?(t.name)
              pending("Not supported in Ruby 1.8")
            elsif %w(n3_10008 n3_10013).include?(t.name)
              pending("Isomorphic compare issue")
            else
              raise
            end
          end
        end
      end
    end

    describe "negative parser tests" do
      negative_tests.each do |t|
        #next unless t.about.uri.to_s =~ /rdfms-empty-property-elements/
        #next unless t.name =~ /1/
        #puts t.inspect
        specify "#{t.name}: #{t.about}" do
          t.run_test do |rdf_string, parser|
            lambda do
              t.debug = []
              g = RDF::Graph.new
              RDF::N3::Reader.new(rdf_string,
                  :base_uri => t.about,
                  :strict => true,
                  :debug => t.debug).each do |statement|
                g << statement
              end
            end.should raise_error(RDF::ReaderError)
          end
        end
      end
    end
  end
end