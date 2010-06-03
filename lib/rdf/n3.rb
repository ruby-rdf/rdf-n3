$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'rdf'

module RDF
  ##
  # **`RDF::N3`** is an Notation-3 plugin for RDF.rb.
  #
  # @example Requiring the `RDF::N3` module
  #   require 'rdf/rdfxml'
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
    require 'n3/format'
    require 'n3/vocab'
    require 'n3/patches/array_hacks'
    require 'n3/patches/rdf_escape'
    autoload :Reader,  'rdf/n3/reader'
    autoload :VERSION, 'rdf/n3/version'
  end
end