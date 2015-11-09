source "https://rubygems.org"

gemspec

group :debug do
  gem "wirble"
  gem "debugger", :platforms => [:mri_19, :mri_20]
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
