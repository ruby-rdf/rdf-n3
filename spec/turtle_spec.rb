$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Reader do
  # W3C Turtle Test suite from http://www.w3.org/TR/turtle/tests/
  describe "w3c turtle tests" do
    require 'turtle_test'

    describe "positive parser tests" do
      Fixtures::TurtleTest::Good.each do |m|
        m.entries.each do |t|
          #puts t.inspect
          specify "#{t.name}: #{t.comment}" do
            # Skip tests for very long files, too long
            if %w(test-14 test-15 test-16).include?(t.name)
              pending("Skip long input file")
          	elsif !defined?(::Encoding) && %w(test-18).include?(t.name)
              pending("Not supported in Ruby 1.8")
            else
              t.debug = [t.inspect, "source:", t.input.read]
              reader = RDF::N3::Reader.new(t.input,
                  :base_uri => t.base_uri,
                  :strict => true,
                  :canonicalize => (%w(test-28).include?(t.name)),
                  :validate => (not %w(test-29).include?(t.name)),
                  :debug => t.debug)
                  
              graph = RDF::Graph.new << reader
              if t.result
                output_graph = RDF::Graph.load(t.result, :base_uri => t.base_uri)
                graph.should be_equivalent_graph(output_graph, self)
              else
                graph.should_not be_empty
              end
            end
          end
        end
      end
    end

    describe "negative parser tests" do
      Fixtures::TurtleTest::Bad.each do |m|
        m.entries.each do |t|
          specify "#{t.name}: #{t.comment}" do
            begin
              lambda {
                t.debug = [t.inspect, "source:", t.input.read]
                reader = RDF::N3::Reader.new(t.input,
                    :base_uri => t.base_uri,
                    :validate => true,
                    :debug => t.debug)
                RDF::Graph.new << reader
              }.should raise_error(RDF::ReaderError)
            rescue RSpec::Expectations::ExpectationNotMetError => e
              pending("N3 is not turtle") {  raise }
            end
          end
        end
      end
    end
  end

end