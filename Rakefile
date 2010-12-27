require 'rubygems'
require 'yard'

begin
  gem 'jeweler'
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rdf-n3"
    gemspec.summary = "Notation-3 (n3-rdf) and Turtle reader/writer for RDF.rb."
    gemspec.description = %q(RDF::N3 is an Notation-3 (n3-rdf) parser for Ruby using the RDF.rb library suite.)
    gemspec.email = "gregg@kellogg-assoc.com"
    gemspec.homepage = "http://github.com/gkellogg/rdf-n3"
    gemspec.authors = ["Gregg Kellogg"]
    gemspec.add_dependency('rdf', '>= 0.3.0')
    gemspec.add_development_dependency('rspec', '>= 2.1.0')
    gemspec.add_development_dependency('rdf-spec', '>= 0.2.1')
    gemspec.add_development_dependency('rdf-rdfxml', '>= 0.2.1')
    gemspec.add_development_dependency('rdf-isomorphic')
    gemspec.add_development_dependency('yard')
    gemspec.extra_rdoc_files     = %w(README.md History.md AUTHORS VERSION)
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc "Run specs through RCov"
RSpec::Core::RakeTask.new("spec:rcov") do |spec|
  spec.rcov = true
  spec.rcov_opts =  %q[--exclude "spec"]
end

desc "Generate HTML report specs"
RSpec::Core::RakeTask.new("doc:spec") do |spec|
  spec.rspec_opts = ["--format", "html", "-o", "doc/spec.html"]
end

YARD::Rake::YardocTask.new do |t|
  t.files   = %w(lib/**/*.rb README.md History.md AUTHORS VERSION)   # optional
end

desc "Generate test manifest yaml"
namespace :spec do
  task :prepare do
    $:.unshift(File.join(File.dirname(__FILE__), 'lib'))
    $:.unshift(File.join(File.dirname(__FILE__), 'spec'))
    require 'rdf/rdfxml'
    require 'rdf/n3'
    require 'rdf_helper'
    require 'fileutils'

    yaml = File.join(SWAP_DIR, "n3parser.yml")
    FileUtils.rm_f(yaml)
    RdfHelper::TestCase.to_yaml(SWAP_TEST, SWAP_DIR, yaml)
    
    yaml = File.join(SWAP_DIR, "regression.yml")
    FileUtils.rm_f(yaml)
    RdfHelper::TestCase.to_yaml(CWM_TEST, SWAP_DIR, yaml)
    
    yaml = File.join(TURTLE_DIR, "manifest.yml")
    FileUtils.rm_f(yaml)
    RdfHelper::TestCase.to_yaml(TURTLE_TEST, TURTLE_DIR, yaml)
    
    yaml = File.join(TURTLE_DIR, "manifest-bad.yml")
    FileUtils.rm_f(yaml)
    RdfHelper::TestCase.to_yaml(TURTLE_BAD_TEST, TURTLE_DIR, yaml)
  end
end

task :default => :spec
