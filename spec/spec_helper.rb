$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'spec'
require 'matchers'
require 'rdf/n3'
require 'rdf/ntriples'
require 'rdf/spec'
require 'rdf/isomorphic'

include Matchers

module RDF
  module Isomorphic
    alias_method :==, :isomorphic_with?
  end
  class Graph
    def to_ntriples
      RDF::Writer.for(:ntriples).buffer do |writer|
        self.each_statement do |statement|
          writer << statement
        end
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.include(RDF::Spec::Matchers)
end

# Heuristically detect the input stream
def detect_format(stream)
  # Got to look into the file to see
  if stream.is_a?(IO) || stream.is_a?(StringIO)
    stream.rewind
    string = stream.read(1000)
    stream.rewind
  else
    string = stream.to_s
  end
  case string
  when /<\w+:RDF/ then RDF::RDFXML::Reader
  when /<RDF/     then RDF::RDFXML::Reader
  when /<html/i   then RDF::RDFa::Reader
  when /@prefix/i then RDF::N3::Reader
  else                 RDF::NTriples::Reader
  end
end
