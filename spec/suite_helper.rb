require 'rdf/n3'
require 'json/ld'

module Fixtures
  module SuiteTest
    BASE = "http://www.w3.org/2000/10/swap/test/"
    CONTEXT = JSON.parse(%q({
      "@vocab": "http://www.w3.org/2004/11/n3test#",

      "inputDocument": {"@type": "@id"},
      "outputDocument": {"@type": "@id"}
    }))

    class Entry < JSON::LD::Resource
      def self.open(file)
        #puts "open: #{file}"
        prefixes = {}
        g = RDF::Repository.load(file, format: :n3)
        JSON::LD::API.fromRDF(g) do |expanded|
          JSON::LD::API.compact(expanded, CONTEXT) do |doc|
            doc['@graph'].each {|r| yield Entry.new(r) if r['@type']}
          end
        end
      end
      attr_accessor :logger

      def base
        inputDocument
      end

      def name
        base.to_s.split('/').last.sub('.n3', '')
      end

      # Alias data and query
      def input
        RDF::Util::File.open_file(inputDocument)
      end

      def expected
        RDF::Util::File.open_file(outputDocument)
      end

      def positive_test?
        !attributes['@type'].match(/Negative/)
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
