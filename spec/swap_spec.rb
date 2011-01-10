$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c swap tests" do
    require 'n3_test'

    # Negative parser tests should raise errors.
    describe "positive parser tests" do
      Fixtures::N3Test::PositiveParserTest.each do |t|
        #next unless t.subject.to_s =~ /rdfms-rdf-names-use/
        #next unless t.name =~ /11/
        #puts t.inspect
        specify "#{t.name}: #{t.inputDocument} against #{t.outputDocument}" do
          begin
            t.run_test do
              t.name.should_not == "n3_10012"  # Too many bnodes makes graph compare unfeasable
              t.debug = []
              g = RDF::Graph.new
              RDF::N3::Reader.new(t.input,
                  :base_uri => t.inputDocument,
                  :strict => true,
                  :debug => t.debug).each do |statement|
                g << statement
              end
              g
            end
          rescue RSpec::Expectations::ExpectationNotMetError => e
            if %w(n3_10012).include?(t.name)
              pending("check visually, graph compare times too long")
            elsif %w(n3_10010).include?(t.name)
              pending("Not supported in Ruby 1.8")
            elsif %w(n3_10008 n3_10013).include?(t.name)
              pending("Isomorphic compare issue")
            elsif %w(n3_10004 n3_10007 n3_10014 n3_10015 n3_10017).include?(t.name)
              pending("Formulae inferrence not supported")
            elsif %w(n3_10006 n3_10009).include?(t.name)
              pending("Verified test results are incorrect")
            else
              raise
            end
          end
        end
      end
    end

    describe "negative parser tests" do
      Fixtures::N3Test::NegativeParserTest.each do |t|
        #next unless t.subject.uri.to_s =~ /rdfms-empty-property-elements/
        #next unless t.name =~ /1/
        #puts t.inspect
        specify "#{t.name}: #{t.inputDocument}#{t.outputDocument ? (' against ' + t.outputDocument) : ''}" do
          begin
            t.run_test do
              lambda do
                t.debug = []
                g = RDF::Graph.new
                RDF::N3::Reader.new(t.input,
                    :base_uri => t.inputDocument,
                    :strict => true,
                    :debug => t.debug).each do |statement|
                  g << statement
                end
              end.should raise_error(RDF::ReaderError)
            end
          rescue RSpec::Expectations::ExpectationNotMetError => e
            if %w(n3_10019 n3_10020).include?(t.name)
              pending("This is still supported")
            else
              raise
            end
          end 
        end
      end
    end
  end
end