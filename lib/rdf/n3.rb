$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))
require 'rdf'

module RDF
  ##
  # **`RDF::N3`** is an Notation-3 plugin for RDF.rb.
  #
  # @example Requiring the `RDF::N3` module
  #   require 'rdf/n3'
  #
  # @example Parsing RDF statements from an N3 file
  #   RDF::N3::Reader.open("etc/foaf.n3") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see http://rdf.rubyforge.org/
  # @see http://www.w3.org/TR/REC-rdf-syntax/
  #
  # @author [Gregg Kellogg](http://kellogg-assoc.com/)
  module N3
    require 'rdf/n3/format'
    require 'rdf/n3/vocab'
    require 'rdf/n3/patches/array_hacks'
    require 'rdf/n3/patches/literal_normalization'
    require 'rdf/n3/patches/graph_properties'
    require 'rdf/n3/patches/qname_hacks'
    require 'rdf/n3/patches/seq'
    require 'rdf/n3/patches/uri_hacks'
    autoload :Reader,  'rdf/n3/reader'
    autoload :VERSION, 'rdf/n3/version'
    autoload :Writer,  'rdf/n3/writer'
    
    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end
  end
end