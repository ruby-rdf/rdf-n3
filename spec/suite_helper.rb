require 'rdf/n3'
require 'json/ld'

# For now, override RDF::Utils::File.open_file to look for the file locally before attempting to retrieve it
module RDF::Util
  module File
    REMOTE_PATH = "http://www.w3.org/2000/10/swap/"
    LOCAL_PATH = ::File.expand_path("../swap", __FILE__) + '/'

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
    def self.open_file(filename_or_url, options = {}, &block)
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
        original_open_file(filename_or_url, options, &block)
      end
    end
  end
end

module Fixtures
  module SuiteTest
    BASE = "http://www.w3.org/2000/10/swap/test/"
    CONTEXT = JSON.parse(%q({
      "n3test": "http://www.w3.org/2004/11/n3test#",

      "inputDocument": {"@id": "n3test:inputDocument", "@type": "@id"},
      "outputDocument": {"@id": "n3test:outputDocument", "@type": "@id"},
      "description": "n3test:description"
    }))

    class Entry < JSON::LD::Resource
      def self.open(file)
        #puts "open: #{file}"
        g = RDF::Repository.load(file, format: :n3)
        JSON::LD::API.fromRDF(g) do |expanded|
          JSON::LD::API.compact(expanded, CONTEXT) do |doc|
            doc['@graph'].map {|r| Entry.new(r)}.
            reject {|r| Array(r.attributes['@type']).empty?}.
            sort_by(&:name).
            each {|t| yield(t)}
          end
        end
      end
      attr_accessor :logger

      # For debug output formatting
      def format; :n3; end

      def base
        inputDocument
      end

      def name
        id.to_s.split('#').last
      end

      # Alias data and query
      def input
        RDF::Util::File.open_file(inputDocument)
      end

      def expected
        RDF::Util::File.open_file(outputDocument)
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
        !outputDocument
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
