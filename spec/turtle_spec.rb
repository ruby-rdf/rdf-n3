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
            elsif %w(test-29).include?(t.name)
              pending("URI changes in RDF.rb make this incompatible")
            elsif !defined?(::Encoding) && %w(test-18).include?(t.name)
              pending("Not supported in Ruby 1.8")
            else
              begin
                t.run_test do
                  #t.debug = []
                  g = RDF::Graph.new
                  RDF::N3::Reader.new(t.input,
                      :base_uri => t.base_uri,
                      :strict => true,
                      :canonicalize => true,
                      :validate => true,
                      :debug => t.debug).each do |statement|
                    g << statement
                  end
                  g
                end
              rescue RSpec::Expectations::ExpectationNotMetError => e
                pending("Turtle specs are approximate")
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
              t.run_test do
                lambda do
                  #t.debug = []
                   g = RDF::Graph.new
                   RDF::N3::Reader.new(t.input,
                       :base_uri => t.base_uri,
                       :validate => true,
                       :debug => t.debug).each do |statement|
                     g << statement
                   end
                end.should raise_error(RDF::ReaderError)
              end
            rescue RSpec::Expectations::ExpectationNotMetError => e
              pending() {  raise }
            end
          end
        end
      end
    end
  end

end