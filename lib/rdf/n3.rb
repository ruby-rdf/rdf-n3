$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))
require 'rdf'

module RDF
  ##
  # **`RDF::N3`** is an Notation-3 extension for RDF.rb.
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
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module N3
    require 'rdf/n3/format'
    require 'rdf/n3/vocab'
    require 'rdf/n3/patches/array_hacks'
    autoload :Meta,    'rdf/n3/reader/meta'
    autoload :Parser,  'rdf/n3/reader/parser'
    autoload :Reader,  'rdf/n3/reader'
    autoload :VERSION, 'rdf/n3/version'
    autoload :Writer,  'rdf/n3/writer'
  end
end