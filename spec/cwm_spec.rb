$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/rdfxml'

describe RDF::N3::Reader do
  describe "w3c cwm tests" do
    require 'rdf_helper'

    def self.test_cases
      RdfHelper::TestCase.test_cases(CWM_TEST, SWAP_DIR)
    end

    # Negative parser tests should raise errors.
    test_cases.each do |t|
      next unless t.about.to_s =~ /n3$/
      #next unless t.about.uri.to_s =~ /rdfms-rdf-names-use/
      #next unless t.name =~ /1018/
      #puts t.inspect
      specify "test #{t.name}: #{t.description}: #{t.inputDocument} against #{t.outputDocument}" do
        begin
          if t.name =~ /1018/
            pending("matcher does not stop")
            next
          end
          t.run_test do |rdf_string|
            t.debug = []
            g = RDF::Graph.new
            RDF::Reader.for(t.inputDocument).new(rdf_string,
                :base_uri => t.about,
                :strict => true,
                :debug => t.debug).each do |statement|
              g << statement
            end
            g
          end
        rescue #Spec::Expectations::ExpectationNotMetError => e
          if t.status == "pending"
            pending("Formulae not supported") {  raise } 
          else
            raise
          end
        end
      end
    end
  end
end