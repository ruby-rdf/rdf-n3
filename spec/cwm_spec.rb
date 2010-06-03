require File.join(File.dirname(__FILE__), 'spec_helper')
include RdfContext

describe "RDF::N3::Reader" do
  describe "w3c cwm tests" do
    require 'rdf_helper'

    def self.test_cases
      RdfHelper::TestCase.test_cases(CWM_TEST, SWAP_DIR) rescue []
    end

    # Negative parser tests should raise errors.
    test_cases.each do |t|
      #next unless t.about.uri.to_s =~ /rdfms-rdf-names-use/
      #next unless t.name =~ /11/
      #puts t.inspect
      specify "test #{t.name}: " + (t.description || "#{t.inputDocument} against #{t.outputDocument}") do
        begin
          t.run_test do |rdf_string, parser|
            parser.parse(rdf_string, t.about.uri.to_s, :strict => true, :debug => [])
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