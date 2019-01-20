require_relative "spec_helper"
require 'rdf/spec'
require 'rdf/n3'
require 'json/ld'
require 'rdf/trig'

module Fixtures
  module Test
    FRAME = JSON.parse(%q({
      "@context": {
        "xsd": "http://www.w3.org/2001/XMLSchema#",
        "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
        "mf": "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
        "mq": "http://www.w3.org/2001/sw/DataAccess/tests/test-query#",
        "n3test": "http://www.w3.org/2000/10/swap/test.n3#",
        "comment": "rdfs:comment",
        "entries": {"@id": "mf:entries", "@container": "@list"},
        "label": "rdfs:label",
        "name": "mf:name",
        "action": {"@id": "mf:action", "@type": "@id"},
        "result": {"@id": "mf:result", "@type": "@id"},
        "options": {"@id": "n3test:options", "@type": "@vocab"},
        "data": {"@id": "n3test:data","@type": "xsd:boolean"},
        "think": {"@id": "n3test:think","@type": "xsd:boolean"}
      },
      "@type": "mf:Manifest",
      "entries": {"@type": "n3test:CwmTest"}
    }))

    class Manifest < JSON::LD::Resource
      attr_accessor :manifest_url

      def self.open(file)
        g = RDF::Repository.load(file, format:  :n3)
        JSON::LD::API.fromRDF(g) do |expanded|
          JSON::LD::API.frame(expanded, FRAME) do |framed|
            yield Manifest.new(framed['@graph'].first, manifest_url: file)
          end
        end
      end

      def initialize(json, manifest_url:)
        @manifest_url = manifest_url
        super
      end

      def entries
        # Map entries to resources
        attributes['entries'].map do |e|
          e.is_a?(String) ? Manifest.open(manifest_url.join(e).to_s) : Entry.new(e, manifest_url: manifest_url)
        end
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :logger
      # For debug output formatting
      def format; :n3; end

      def base
        action
      end

      # Alias data and query
      def input
        @input ||= RDF::Util::File.open_file(action) {|f| f.read}
      end

      def expected
        @expected ||= RDF::Util::File.open_file(result) {|f| f.read}
      end

      def positive_test?
        !attributes['@type'].to_s.match(/Negative/)
      end

      def negative_test?
        !positive_test?
      end

      def evaluate?
        !syntax?
      end

      def syntax?
        !result
      end

      def inspect
        super.sub('>', "\n" +
        "  positive?: #{positive_test?.inspect}\n" +
        ">"
      )
      end
    end
  end
end

describe RDF::N3::Reader do
  Fixtures::Test::Manifest.open(File.expand_path("../test-files/manifest.n3", __FILE__)) do |m|
    describe m.label do
      m.entries.each do |t|
        specify "#{t.id.split('#').last}: #{t.name} - #{t.comment}" do
          t.logger = RDF::Spec.logger
          t.logger.info t.inspect
          t.logger.info "source:\n#{t.input}"

          case t.id.split('#').last
          when *%w{listin bnode concat t2006}
            pending "support for lists"
          when *%w{t1018b2 t103 t104 t105 concat}
            pending "support for string"
          when *%w{t2005 t555}
            pending "understanding output filtering"
          when *%w{t06proof}
            pending "support for math"
          when *%w{t01}
            pending "support for log:supports"
          when *%w{conclusion-simple conclusion}
            pending "support for log:conclusion"
          when *%w{conjunction}
            pending "support for log:conjunction"
          when *%w{t553 t554}
            pending "support for inference over quoted graphs"
          end

          reader = RDF::N3::Reader.new(t.input,
              base_uri:  t.base,
              logger: t.logger)

          reasoner = RDF::N3::Reasoner.new(t.input,
              base_uri:  t.base,
              logger: t.logger)

          repo = RDF::Repository.new

          if t.positive_test?
            begin
              if t.options["think"]
                repo = reasoner.execute(logger: t.logger, think: t.options['think'])
              else
                repo << reader
              end
            rescue Exception => e
              expect(e.message).to produce("Not exception #{e.inspect}", t)
            end
            if t.evaluate?
              output_repo = RDF::Repository.load(t.result, format: :n3, base_uri:  t.base)
              repo = repo.project_graph(nil) if t.options['data']
              expect(repo).to be_equivalent_graph(output_repo, t)
            else
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