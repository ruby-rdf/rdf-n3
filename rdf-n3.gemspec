#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version               = File.read('VERSION').chomp
  gem.date                  = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name                  = %q{rdf-n3}
  gem.homepage              = %q{https://ruby-rdf.github.com/rdf-n3}
  gem.license               = 'Unlicense'
  gem.summary               = %q{Notation3 reader/writer and reasoner for RDF.rb.}
  gem.description           = %q{RDF::N3 is an Notation-3 reader/writer and reasoner for the RDF.rb library suite.}

  gem.authors               = %w(Gregg Kellogg)
  gem.email                 = 'public-rdf-ruby@w3.org'

  gem.platform              = Gem::Platform::RUBY
  gem.files                 = %w(README.md VERSION UNLICENSE) + Dir.glob('lib/**/*.rb')
  gem.require_paths         = %w(lib)

  gem.required_ruby_version = '>= 2.4'
  gem.requirements          = []

  gem.add_dependency             'ebnf',            '~> 2.1'
  gem.add_dependency             'rdf',             '~> 3.1', '>= 3.1.12'
  gem.add_dependency             'sparql',          '~> 3.1', '>= 3.1.4'
  gem.add_runtime_dependency     'sxp',             '~> 1.1'

  gem.add_development_dependency 'json-ld',         '~> 3.1'
  gem.add_development_dependency 'rdf-spec',        '~> 3.1'
  gem.add_development_dependency 'rdf-isomorphic',  '~> 3.1'
  gem.add_development_dependency 'rdf-trig',        '~> 3.1'
  gem.add_development_dependency 'rdf-vocab',       '~> 3.1'
  gem.add_development_dependency 'rspec',           '~> 3.10'
  gem.add_development_dependency 'rspec-its',       '~> 1.3'
  gem.add_development_dependency 'yard' ,           '~> 0.9'

  gem.post_install_message  = nil
end

