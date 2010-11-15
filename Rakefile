require 'rubygems'
require 'yard'

begin
  gem 'jeweler'
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rdf-n3"
    gemspec.summary = "Notation-3 (n3-rdf) and Turtle reader/writer for RDF.rb."
    gemspec.description = %w(RDF::N3 is an Notation-3 (n3-rdf) parser for Ruby using the RDF.rb library suite.)
    gemspec.email = "gregg@kellogg-assoc.com"
    gemspec.homepage = "http://github.com/gkellogg/rdf-rdfa"
    gemspec.authors = ["Gregg Kellogg"]
    gemspec.add_dependency('rdf', '>= 0.2.3')
    gemspec.add_dependency('treetop',  '>= 1.4.0')
    gemspec.add_development_dependency('rspec', '= 1.3.0')
    gemspec.add_development_dependency('rdf-spec', '>= 0.2.1')
    gemspec.add_development_dependency('rdf-rdfxml', '>= 0.2.1')
    gemspec.add_development_dependency('rdf-isomorphic')
    gemspec.add_development_dependency('yard')
    gemspec.extra_rdoc_files     = %w(README.rdoc History.txt AUTHORS)
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/*_spec.rb']
end

desc "Run specs through RCov"
Spec::Rake::SpecTask.new("spec:rcov") do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/*_spec.rb'
  spec.rcov = true
end

desc "Generate HTML report specs"
Spec::Rake::SpecTask.new("doc:spec") do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/*_spec.rb']
  spec.spec_opts = ["--format", "html:doc/spec.html"]
end

YARD::Rake::YardocTask.new do |t|
  t.files   = %w(lib/**/*.rb README.rdoc History.txt AUTHORS)   # optional
end

desc "Update N3 grammar"
task :grammar do
  sh "tt -o lib/rdf/n3/reader/n3_grammar.rb lib/rdf/n3/reader/n3_grammar.treetop"
  sh "tt -o lib/rdf/n3/reader/n3_grammar_18.rb lib/rdf/n3/reader/n3_grammar_18.treetop"
end

desc "Generate test manifest yaml"
namespace :spec do
  task :prepare do
    $:.unshift(File.join(File.dirname(__FILE__), 'lib'))
    require 'rdf/rdfxml'
    require 'rdf/n3'
    require 'spec/rdf_helper'
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
    RdfHelper::TestCase.to_yaml(TURTLE_TEST, TURTLE_DIR, yaml)
  end
end

task :default => :spec
