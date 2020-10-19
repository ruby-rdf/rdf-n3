require_relative 'spec_helper'
require 'rdf/trig'  # For formatting error descriptions

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c n3 tests" do
    require_relative 'suite_helper'
    let(:logger) {RDF::Spec.logger}
    before {logger.level = Logger::INFO}

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
            when *%w{cwm_unify_unify1 cwm_includes_builtins
                     cwm_includes_t10 cwm_includes_t11 cwm_includes_quantifiers_limited
                     cwm_includes_conclusion_simple cwm_includes_conclusion}
              pending "log:includes etc."
            when *%w{cwm_supports_simple cwm_string_roughly}
              pending "Uses unsupported builtin"
            when *%w{cwm_string_uriEncode}
              skip "Blows up"
            when *%w{cwm_list_builtin_generated_match}
              skip("List reification")
            end

            t.logger = logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            reader = RDF::N3::Reader.new(t.input,
                base_uri: t.base,
                canonicalize: false,
                list_terms: true,
                validate: false,
                logger: false)

            reasoner = RDF::N3::Reasoner.new(reader,
                base_uri:  t.base,
                logger: t.logger)

            repo = RDF::N3:: Repository.new

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
                output_repo = RDF:: Repository.load(t.result, format: :n3, base_uri:  t.base)

                # Check against expanded triples from repo
                expanded_repo = RDF::Repository.new do |r|
                  repo.each_expanded_statement do |st|
                    r << st
                  end
                end
                expect(expanded_repo).to be_equivalent_graph(output_repo, t)
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