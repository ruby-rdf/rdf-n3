$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Reader do
  describe "w3c cwm tests" do
    require 'cwm_test'

    # Negative parser tests should raise errors.
    Fixtures::Cwm::CwmTest.each do |t|
      next unless t.inputDocument
      #next unless t.about.uri.to_s =~ /rdfms-rdf-names-use/
      #next unless t.name =~ /1018/
      #puts t.inspect
      specify "test #{t.name}: #{t.description}: #{t.inputDocument} against #{t.referenceOutput}" do
        begin
          if t.name =~ /1018/
            pending("matcher does not stop")
            next
          elsif !t.arguments.to_s.empty?
            pending("proofs not supported")
            next
          end
          t.run_test do
            t.debug = []
            g = RDF::Graph.new
            RDF::Reader.for(t.inputDocument).new(t.input,
                :base_uri => t.inputDocument,
                :strict => true,
                :debug => t.debug).each do |statement|
              g << statement
            end
            g
          end
        rescue RSpec::Expectations::ExpectationNotMetError => e
          if t.status == "pending"
            pending("Formulae not supported") {  raise } 
          else
            raise
          end
        end
      end
    end
  end
end unless ENV['CI'] || true