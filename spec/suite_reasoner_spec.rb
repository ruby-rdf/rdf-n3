require_relative 'spec_helper'
require 'rdf/trig'  # For formatting error descriptions

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c n3 tests" do
    require_relative 'suite_helper'
    let(:logger) {RDF::Spec.logger}

    #after(:each) do |example|
    #  puts logger.to_s if
    #    example.exception &&
    #    !example.exception.is_a?(RSpec::Expectations::ExpectationNotMetError)
    #end

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/N3/tests/N3Tests/manifest-reasoner.ttl") do |m|
      describe m.label do
        m.entries.each do |t|
          next if t.approval == 'rdft:Rejected'
          specify "#{t.name}: #{t.comment}" do
            case t.id.split('#').last
            when *%w{cwm_includes_listin cwm_includes_bnode cwm_includes_concat
                     cwm_includes_conjunction cwm_includes_conclusion_simple
                     cwm_list_append}
              pending "support for lists"
            when *%w{cwm_unify_unify1 cwm_unify_unify2}
              pending "reason over formulae"
            when *%w{cwm_reason_t6}
              pending "support for math"
            when *%w{cwm_supports_simple cwm_string_roughly cwm_string_uriEncode}
              pending "Uses unsupported builtin"
            when *%w{cwm_reason_t2 cwm_list_builtin_generated_match cwm_reason_double}
              skip("Not allowed with new grammar")
            end

            t.logger = logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            reader = RDF::N3::Reader.new(t.input,
                base_uri: t.base,
                canonicalize: false,
                validate: false,
                logger: false)

            reasoner = RDF::N3::Reasoner.new(reader,
                base_uri:  t.base,
                logger: t.logger)

            repo = RDF::Repository.new

            if t.positive_test?
              begin
                reasoner.execute(logger: t.logger, think: !!t.options['think'])
                if t.options["filter"]
                  repo << reasoner.conclusions
                elsif t.options["data"]
                  repo << reasoner.data
                else
                  repo << reasoner
                end
              rescue Exception => e
                expect(e.message).to produce("Not exception #{e.inspect}: #{e.backtrace.join("\n")}", t)
              end

              t.logger.info "result:\n#{repo.dump(:n3)}"
              if t.evaluate? || t.reason?
                output_repo = RDF::Repository.load(t.result, format: :n3, base_uri:  t.base)
                expect(repo).to be_equivalent_graph(output_repo, t)
              else
              end
            else
              expect {
                repo << reader
                expect(repo.dump(:nquads)).to produce("not this", t)
              }.to raise_error(RDF::ReaderError)
            end
          end
        end
      end
    end
  end
end unless ENV['CI']