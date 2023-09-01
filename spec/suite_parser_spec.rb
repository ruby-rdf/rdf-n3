require_relative 'spec_helper'
require 'rdf/trig'  # For formatting error descriptions

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c n3 tests" do
    let(:logger) {RDF::Spec.logger}
    before {logger.level = Logger::INFO if ENV['CI']}

    after(:each) do |example|
      puts logger.to_s if
        example.exception &&
        !example.exception.is_a?(RSpec::Expectations::ExpectationNotMetError)
    end

    require_relative 'suite_helper'

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/N3/tests/N3Tests/manifest-parser.ttl") do |m|
      describe m.label do
        m.entries.each do |t|
          next if t.approval == 'rdft:Rejected'
          specify "#{t.rel}: #{t.name}: #{t.comment}" do
            case t.rel
            when *%w(cwm_syntax_numbers.n3)
              pending("number representation")
            when *%w(cwm_syntax_too-nested.n3)
              skip("stack overflow")
            end

            t.logger = logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            reader = RDF::N3::Reader.new(t.input,
                base_uri: t.base,
                canonicalize: false,
                validate: true,
                logger: t.logger)

            repo = [].extend(RDF::Enumerable, RDF::Queryable)

            output_repo = if t.evaluate?
              begin
                format = detect_format(t.expected)
                RDF::N3:: Repository.load(t.result, format: format, base_uri: t.accept)
              rescue Exception => e
                expect(e.message).to produce("Exception loading output #{e.inspect}", t)
              end
            end

            if t.positive_test?
              begin
                reader.each_statement {|st| repo << st}
              rescue Exception => e
                expect(e.message).to produce("Not exception #{e.inspect}", t)
              end

              if t.evaluate?
                expect(repo).to be_equivalent_graph(output_repo, t)
              else
                expect(repo).to be_enumerable
              end
            elsif t.syntax?
              expect {
                reader.each_statement {|st| repo << st}
                expect(repo.count).to produce("not this", t)
              }.to raise_error(RDF::ReaderError)
            else
              expect(repo).not_to be_equivalent_graph(output_repo, t)
            end
          end
        end
      end
    end
  end
end