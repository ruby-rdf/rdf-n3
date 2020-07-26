require 'rdf/turtle'
require 'rdf/n3'
require 'json/ld'

# For now, override RDF::Utils::File.open_file to look for the file locally before attempting to retrieve it
module RDF::Util
  module File
    REMOTE_PATH = "https://w3c.github.io/N3/"
    LOCAL_PATH = ::File.expand_path("../w3c-N3", __FILE__) + '/'

    class << self
      alias_method :original_open_file, :open_file
    end

    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, **options, &block)
      case 
      when filename_or_url.to_s =~ /^file:/
        path = filename_or_url[5..-1]
        Kernel.open(path.to_s, options, &block)
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH}} && Dir.exist?(LOCAL_PATH))
        #puts "attempt to open #{filename_or_url} locally"
        localpath = filename_or_url.to_s.sub(REMOTE_PATH, LOCAL_PATH)
        response = begin
          ::File.open(localpath)
        rescue Errno::ENOENT => e
          raise IOError, e.message
        end
        document_options = {
          base_uri:     RDF::URI(filename_or_url),
          charset:      Encoding::UTF_8,
          code:         200,
          headers:      {}
        }
        #puts "use #{filename_or_url} locally"
        document_options[:headers][:content_type] = case filename_or_url.to_s
        when /\.ttl$/    then 'text/turtle'
        when /\.n3$/      then 'text/n3'
        when /\.nt$/     then 'application/n-triples'
        when /\.jsonld$/ then 'application/ld+json'
        else                  'unknown'
        end

        document_options[:headers][:content_type] = response.content_type if response.respond_to?(:content_type)
        # For overriding content type from test data
        document_options[:headers][:content_type] = options[:contentType] if options[:contentType]

        remote_document = RDF::Util::File::RemoteDocument.new(response.read, document_options)
        if block_given?
          yield remote_document
        else
          remote_document
        end
      else
        original_open_file(filename_or_url, **options, &block)
      end
    end
  end
end

module Fixtures
  module SuiteTest
    FRAME = JSON.parse(%q({
      "@context": {
        "xsd": "http://www.w3.org/2001/XMLSchema#",
        "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
        "mf": "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
        "mq": "http://www.w3.org/2001/sw/DataAccess/tests/test-query#",
        "rdft": "http://www.w3.org/ns/rdftest#",
        "test": "https://w3c.github.io/N3/tests/test.n3#",
        "action": {"@id": "mf:action", "@type": "@id"},
        "approval": {"@id": "rdft:approval", "@type": "@vocab"},
        "comment": "rdfs:comment",
        "data": {"@id": "test:data", "@type": "xsd:boolean"},
        "entries": {"@id": "mf:entries", "@container": "@list"},
        "filter": {"@id": "test:filter", "@type": "xsd:boolean"},
        "name": "mf:name",
        "options": {"@id": "test:options", "@type": "@id"},
        "result": {"@id": "mf:result", "@type": "@id"},
        "rules": {"@id": "test:rules", "@type": "xsd:boolean"},
        "think": {"@id": "test:think", "@type": "xsd:boolean"}
      },
      "@type": "mf:Manifest",
      "entries": {
        "@type": [
          "test:TestN3Reason",
          "test:TestN3Eval",
          "test:TestN3PositiveSyntax",
          "test:TestN3NegativeSyntax"
        ]
      }
    }))
 
    class Manifest < JSON::LD::Resource
      def self.open(file)
        #puts "open: #{file}"
        g = RDF::Repository.load(file)
        JSON::LD::API.fromRDF(g) do |expanded|
          JSON::LD::API.frame(expanded, FRAME) do |framed|
            yield Manifest.new(framed)
          end
        end
      end

      def entries
        # Map entries to resources
        attributes['entries'].map {|e| Entry.new(e)}
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :logger

      # For debug output formatting
      def format; :n3; end

      # For debug output formatting
      def format; :ttl; end

      def base
        action
      end

      def name
        id.to_s.split('#').last
      end

      # Alias data and query
      def input
        @input ||= RDF::Util::File.open_file(action) {|f| f.read}
      end

      def expected
        @expected ||= RDF::Util::File.open_file(result) {|f| f.read}
      end

      def positive_test?
        attributes['@type'].to_s.match?(/N3Positive|N3Eval|N3Reason/)
      end

      def negative_test?
        attributes['@type'].to_s.match?(/N3Negative/)
      end

      def evaluate?
        !!attributes['@type'].to_s.match?(/N3Eval/)
      end

      def reason?
        !!attributes['@type'].to_s.match?(/N3Reason/)
      end

      def syntax?
        !!attributes['@type'].to_s.match?(/Syntax/)
      end

      def inspect
        super.sub(/>$/, "\n" +
        "  positive?: #{positive_test?.inspect}\n" +
        "  syntax?: #{syntax?.inspect}\n" +
        "  eval?: #{evaluate?.inspect}\n" +
        "  reason?: #{reason?.inspect}\n" +
        ">"
      )
      end
    end
  end
end
