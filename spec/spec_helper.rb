$:.unshift(File.expand_path('../../lib', __FILE__))

require "bundler/setup"
require 'rspec'
require 'rdf/isomorphic'
require 'rdf/ntriples'
require 'rdf/spec'
require 'rdf/spec/matchers'
require_relative 'matchers'

begin
  require 'simplecov'
  require 'simplecov-lcov'
  SimpleCov::Formatter::LcovFormatter.config do |config|
    #Coveralls is coverage by default/lcov. Send info results
    config.report_with_single_file = true
    config.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError => e
  STDERR.puts "Coverage Skipped: #{e.message}"
end
require 'rdf/n3'

::RSpec.configure do |c|
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  c.filter_run_excluding slow: true unless ENV['SLOW']
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
  when /<\w+:RDF/ then :rdfxml
  when /<RDF/     then :rdfxml
  when /<html/i   then :rdfa
  when /@prefix/i then :n3
  else                 :n3
  end
end
