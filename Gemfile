source "https://rubygems.org"

gemspec

gem 'rdf',                git: "https://github.com/ruby-rdf/rdf",                 branch: "develop"
gem 'sparql',             git: "https://github.com/ruby-rdf/sparql",              branch: "develop"
gem 'sxp',                git: "https://github.com/dryruby/sxp.rb",               branch: "develop"

group :development do
  gem 'ebnf',               git: "https://github.com/dryruby/ebnf",                 branch: "develop"
  gem 'json-ld',            git: "https://github.com/ruby-rdf/json-ld",             branch: "develop"
  gem 'rdf-aggregate-repo', git: "https://github.com/ruby-rdf/rdf-aggregate-repo",  branch: "develop"
  gem 'rdf-isomorphic',     git: "https://github.com/ruby-rdf/rdf-isomorphic",      branch: "develop"
  gem 'rdf-spec',           git: "https://github.com/ruby-rdf/rdf-spec",            branch: "develop"
  gem 'rdf-trig',           git: "https://github.com/ruby-rdf/rdf-trig",            branch: "develop"
  gem 'rdf-turtle',         git: "https://github.com/ruby-rdf/rdf-turtle",          branch: "develop"
  gem 'rdf-vocab',          git: "https://github.com/ruby-rdf/rdf-vocab",           branch: "develop"
  gem 'rdf-xsd',            git: "https://github.com/ruby-rdf/rdf-xsd",             branch: "develop"
  gem 'sparql-client',      git: "https://github.com/ruby-rdf/sparql-client",       branch: "develop"
end

group :development, :test do
  gem 'simplecov', '~> 0.22',  platforms: :mri
  gem 'simplecov-lcov', '~> 0.8',  platforms: :mri
end

group :debug do
  gem 'byebug', platform: :mri
end
