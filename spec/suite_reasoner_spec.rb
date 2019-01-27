require_relative 'spec_helper'
require 'rdf/trig'  # For formatting error descriptions

describe RDF::N3::Reader do
  # W3C N3 Test suite from http://www.w3.org/2000/10/swap/test/n3parser.tests
  describe "w3c n3 tests" do
    require_relative 'suite_helper'

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/n3/tests/manifest-reasoner.n3") do |m|
      describe m.label do
        m.entries.each do |t|
          specify "#{t.name}: #{t.comment}" do
            case t.id.split('#').last
            when *%w{listin bnode concat t2006}
              pending "support for lists"
            when *%w{t1018b2 t103 t104 t105 concat}
              pending "support for string"
            when *%w{t06proof}
              pending "support for math"
            when *%w{t01}
              pending "support for log:supports"
            when *%w{conclusion-simple conclusion}
              pending "support for log:conclusion"
            when *%w{conjunction}
              pending "support for log:conjunction"
            when *%w{t553}
              pending "support for inference over quoted graphs"
            when *%w{t2005}
              pending "something else"
            end

            t.logger = RDF::Spec.logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            reader = RDF::N3::Reader.new(t.input,
                base_uri: t.base,
                canonicalize: false,
                validate: false)

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
              if t.evaluate? || t.reason?
                output_repo = RDF::Repository.load(t.result, format: :n3, base_uri:  t.base)
                expect(repo).to be_equivalent_graph(output_repo, t)
              else
              end
            else
              expect {
                graph << reader
                expect(graph.dump(:nquads)).to produce("not this", t)
              }.to raise_error(RDF::ReaderError)
            end
          end
        end
      end
    end
  end
end unless ENV['CI']