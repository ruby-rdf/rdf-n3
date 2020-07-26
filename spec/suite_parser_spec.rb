require_relative 'spec_helper'
require 'rdf/trig'  # For formatting error descriptions

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c n3 tests" do
    let(:logger) {RDF::Spec.logger}

    after(:each) do |example|
      puts logger.to_s if
        example.exception &&
        !example.exception.is_a?(RSpec::Expectations::ExpectationNotMetError)
    end

    require_relative 'suite_helper'

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/N3/grammar/tests/N3Tests/manifest.ttl") do |m|
      describe m.label do
        m.entries.each do |t|
          # Skip non-cwm entries, for now
          next unless t.name.start_with?('cwm')
          specify "#{t.name}: #{t.comment}" do
            case t.name
            #when *%w(04test_metastaticP.n3)
            #  skip("it was decided not to allow this")
            #when *%w(04test_icalQ002.n3 04test_query-survey-11.n3)
            #  pending("datatype (^^) tag and @language for quick-vars")
            when *%w(cwm_math_trigo-test.n3)
              pending("dependency on prefixes")
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

            repo = RDF::Repository.new

            output_repo = if t.evaluate?
              begin
                format = detect_format(t.expected)
                RDF::Repository.load(t.result, format: format, base_uri: t.accept)
              rescue Exception => e
                expect(e.message).to produce("Exception loading output #{e.inspect}", t)
              end
            end

            if t.positive_test?
              begin
                repo << reader
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
                repo << reader
                require 'byebug'; byebug
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
end unless ENV['CI']