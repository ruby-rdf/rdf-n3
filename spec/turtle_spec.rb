$:.unshift "."
require 'spec_helper'

describe RDF::N3::Reader do
  # W3C Turtle Test suite from http://w3c.github.io/rdf-tests/turtle/manifest.ttl
  describe "w3c turtle tests" do
    require 'suite_helper'

    Fixtures::TurtleTest::Manifest.open("http://w3c.github.io/rdf-tests/turtle/manifest.ttl") do |m|
      describe m.comment do
        m.entries.each do |t|
          specify "#{t.name}: #{t.comment}" do
            t.logger = RDF::Spec.logger
            t.logger.info t.inspect
            t.logger.info "source:\n#{t.input}"

            case t.name
            when *%w(turtle-syntax-bad-uri-01)
              skip("Spaces allowed in IRIs")
            when *%w(turtle-syntax-bad-prefix-01 turtle-syntax-bad-prefix-02)
              skip("No prefixes okay")
            when *%w(turtle-syntax-bad-struct-02 turtle-syntax-bad-struct-04 turtle-syntax-bad-struct-06
                     turtle-syntax-bad-struct-07 turtle-syntax-bad-kw-04 turtle-syntax-bad-n3-extras-01
                     turtle-syntax-bad-n3-extras-02 turtle-syntax-bad-n3-extras-03
                     turtle-syntax-bad-n3-extras-04 turtle-syntax-bad-n3-extras-05
                     turtle-syntax-bad-n3-extras-06 turtle-syntax-bad-n3-extras-09
                     turtle-syntax-bad-n3-extras-10 turtle-syntax-bad-n3-extras-11
                     turtle-syntax-bad-n3-extras-12 turtle-syntax-bad-struct-14
                     turtle-syntax-bad-struct-16 turtle-syntax-bad-struct-17)
              skip("This is, in fact, N3")
            end

            reader = RDF::N3::Reader.new(t.input,
                base_uri:  t.base,
                canonicalize:  false,
                validate:  true,
                logger: t.logger)

            graph = RDF::Repository.new

            if t.positive_test?
              begin
                graph << reader
              rescue Exception => e
                expect(e.message).to produce("Not exception #{e.inspect}", t)
              end

              if t.evaluate?
                output_graph = RDF::Repository.load(t.result, format: :ntriples, base_uri:  t.base)
                expect(graph).to be_equivalent_graph(output_graph, t)
              else
                expect(graph).to be_a(RDF::Enumerable)
              end
            else
              expect {
                graph << reader
                expect(graph.dump(:ntriples)).to produce("not this", t)
              }.to raise_error(RDF::ReaderError)
            end
          end
        end
      end
    end
  end
end unless ENV['CI']