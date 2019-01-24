require_relative 'spec_helper'
require 'rdf/trig'  # For formatting error descriptions

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c n3 tests" do
    require_relative 'suite_helper'

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/n3/tests/manifest-parser.n3") do |m|
      describe m.label do
        m.entries.each do |t|
          specify "#{t.name}: #{t.description}" do
            case t.name
            when *%w(n3_10004 n3_10007 n3_10014 n3_10015 n3_10017)
              pending("Reification not supported")
            when *%w(n3_10013)
              pending("numeric representation")
            when *%w(n3_10003 n3_10006)
              pending("Verified test results are incorrect")
            end

            t.logger = RDF::Spec.logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            reader = RDF::N3::Reader.new(t.input,
                base_uri: t.base,
                canonicalize: false,
                validate: true,
                logger: t.logger)

            repo = RDF::Repository.new

            output_repo = if t.evaluate?
              begin
                format = detect_format(t.expected)
                RDF::Repository.load(t.result, format: format, base_uri: t.accept)
              rescue Exception => e
                expect(e.message).to produce("Exception loading output #{e.inspect}", t.logger)
              end
            end

            if t.positive_test?
              begin
                repo << reader
              rescue Exception => e
                expect(e.message).to produce("Not exception #{e.inspect}", t.logger)
              end

              if t.evaluate?
                expect(repo).to be_equivalent_graph(output_repo, t)
              else
                expect(repo).to be_enumerable
              end
            elsif t.syntax?
              expect {
                repo << reader
                repo.dump(:nquads).should produce("not this", t.logger)
              }.to raise_error(RDF::ReaderError)
            else
              expect(repo).not_to be_equivalent_graph(output_repo, t)
            end
          end
        end
      end
    end
  end
end unless ENV['CI']