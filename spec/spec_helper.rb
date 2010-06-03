$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'spec'
require 'rdf/n3'
require 'rdf/spec'

Spec::Runner.configure do |config|
  config.include(RDF::Spec::Matchers)
end
