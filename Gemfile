source "https://rubygems.org"

gemspec

gem "rdf",              github: "ruby-rdf/rdf", branch: "develop"

group :development do
  gem "rdf-spec",       github: "ruby-rdf/rdf-spec", branch: "develop"
  gem "rdf-isomorphic", github: "ruby-rdf/rdf-isomorphic", branch: "develop"
  gem "rdf-xsd",        github: "ruby-rdf/rdf-xsd", branch: "develop"
  gem "json-ld",        github: "ruby-rdf/json-ld", branch: "develop"
end

group :debug do
  gem "byebug", platform: :mri
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
