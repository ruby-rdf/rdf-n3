$:.unshift "."
require 'spec_helper'

describe RDF::N3::Reader do
  # W3C Turtle Test suite from http://w3c.github.io/rdf-tests/turtle/manifest.ttl
  describe "w3c turtle tests" do
    require 'suite_helper'

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/N3/tests/TurtleTests/manifest.ttl") do |m|
      describe m.comment do
        m.entries.each do |t|
          next if t.approval == 'rdft:Rejected'
          specify "#{t.name}: #{t.comment}" do
            t.logger = RDF::Spec.logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            reader = RDF::N3::Reader.new(t.input,
                base_uri:  t.base,
                canonicalize:  false,
                validate:  true,
                logger: t.logger)

            graph = [].extend(RDF::Enumerable, RDF::Queryable)

            if t.positive_test?
              begin
                reader.each_statement {|st| graph << st}
              rescue Exception => e
                expect(e.message).to produce("Not exception #{e.inspect}", t)
              end

              if t.evaluate?
                output_graph = RDF::Repository.load(t.result, format: :ntriples, base_uri: t.base)
                expect(graph).to be_equivalent_graph(output_graph, t)
              else
                expect(graph).to be_a(RDF::Enumerable)
              end
            else
              expect {
                reader.each_statement {|st| graph << st}
                expect(graph.dump(:ntriples)).to produce("not this", t)
              }.to raise_error(RDF::ReaderError)
            end
          end
        end
      end
    end
  end
end unless ENV['CI']