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
    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/N3/tests/N3Tests/manifest-extended.ttl") do |m|
      describe m.label do
        m.entries.each do |t|
          next if t.approval == 'rdft:Rejected'
          specify "#{t.rel}: #{t.name}: #{t.comment}", slow: t.slow? do
            case t.rel
            when *%w(07test_utf8.n3)
              pending("invalid byte sequence in UTF-8")
            when *%w(01etc_skos-extra-rules.n3 01etc_skos-rules.n3 07test_pd_hes_theory.n3)
              pending("@keywords")
            when *%w(01etc_train_model.n3 04test_icalQ002.n3 04test_icalR.n3 04test_LanguageQ.n3
                     04test_LanguageQ.n3 04test_query-survey-11.n3 04test_query-survey-13.n3
                     04test_icalQ001.n3)
              pending("variable filter syntax")
            when *%w(04test_ontology-for-data-model.n3)
              pending("invalid literal")
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
end unless ENV['CI']