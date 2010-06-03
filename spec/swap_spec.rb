require File.join(File.dirname(__FILE__), 'spec_helper')
include RdfContext

describe "N3 parser" do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c swap tests" do
    require 'rdf_helper'

    def self.positive_tests
      RdfHelper::TestCase.positive_parser_tests(SWAP_TEST, SWAP_DIR) rescue []
    end

    def self.negative_tests
      RdfHelper::TestCase.negative_parser_tests(SWAP_TEST, SWAP_DIR) rescue []
    end

    # Negative parser tests should raise errors.
    describe "positive parser tests" do
      positive_tests.each do |t|
        #next unless t.about.uri.to_s =~ /rdfms-rdf-names-use/
        #next unless t.name =~ /11/
        #puts t.inspect
        specify "#{t.name}: #{t.about.uri.to_s} against #{t.outputDocument}" do
          begin
            t.run_test do |rdf_string, parser|
              t.name.should_not == "n3_10012"  # Too many bnodes makes graph compare unfeasable
              parser.parse(rdf_string, t.about.uri.to_s, :strict => true, :debug => [])
            end
          rescue #Spec::Expectations::ExpectationNotMetError => e
            if %w(n3_10003 n3_10004).include?(t.name)
              pending("@forAll/@forEach not yet implemented")
            elsif %w(n3_10007 n3_10014 n3_10015 n3_10017).include?(t.name)
              pending("formulae not yet implemented")
            elsif %w(n3_10012).include?(t.name)
              pending("check visually, graph compare times too long")
            elsif %w(n3_10010).include?(t.name)
              pending("Not supported in Ruby 1.8")
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
        specify "#{t.name}: #{t.about.uri.to_s}" do
          t.run_test do |rdf_string, parser|
            if !defined?(::Encoding) && %w(n3_10019 n3_10020).include?(t.name)
              pending("Not supported in Ruby 1.8")
              return
            end
            begin
              lambda do
                parser.parse(rdf_string, t.about.uri.to_s, :strict => true, :debug => [])
              end.should raise_error(RdfException)
            rescue Spec::Expectations::ExpectationNotMetError => e
              if %w().include?(t.name)
                pending("@forAll/@forEach not yet implemented")
              elsif %w(n3_10019 n3_10020 n3_20005).include?(t.name.to_s)
                pending("formulae not yet implemented")
              elsif %w(n3_20000).include?(t.name)
                pending("figure out how to tell that these are errors")
              else
                raise
              end
            end
          end
        end
      end
    end
  end
end