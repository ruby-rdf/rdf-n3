$:.unshift "."
require 'spec_helper'

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c swap tests" do
    require 'swap_test'

    # Negative parser tests should raise errors.
    describe "positive parser tests" do
      Fixtures::SWAPTest::PositiveParserTest.each do |t|
        #next unless t.subject.to_s =~ /rdfms-rdf-names-use/
        #next unless t.name =~ /11/
        #puts t.inspect
        specify "#{t.name}: #{t.inputDocument} against #{t.outputDocument}" do
          if %w(n3_10012).include?(t.name)
            pending("Skip long input file")
          elsif %w(n3_10004 n3_10007 n3_10014 n3_10015 n3_10017).include?(t.name)
            pending("Formulae inferrence not supported")
          elsif %w(n3_10006 n3_10009).include?(t.name)
            pending("Verified test results are incorrect")
          elsif %w(n3_10008 n3_10013).include?(t.name)
            pending("Isomorphic compare issue")
          elsif %w(n3_10003).include?(t.name)
            pending("BNode as predicate")
          else
            t.debug = [t.inspect, "source:", t.input.read]
            reader = RDF::N3::Reader.new(t.input,
                :base_uri => t.inputDocument,
                :strict => true,
                :debug => t.debug)
                  
            graph = RDF::Graph.new << reader
            graph.should be_equivalent_graph(t.output.read, self) if t.outputDocument
          end
        end
      end
    end

    describe "negative parser tests" do
      Fixtures::SWAPTest::NegativeParserTest.each do |t|
        #next unless t.subject.uri.to_s =~ /rdfms-empty-property-elements/
        #next unless t.name =~ /1/
        #puts t.inspect
        specify "#{t.name}: #{t.inputDocument}#{t.outputDocument ? (' against ' + t.outputDocument) : ''}" do
          lambda {
            t.debug = [t.inspect, "source:", t.input.read]
            reader = RDF::N3::Reader.new(t.input,
                :base_uri => t.inputDocument,
                :strict => true,
                :debug => t.debug)
            RDF::Graph.new << reader
          }.should raise_error(RDF::ReaderError)
        end
      end
    end
  end
end