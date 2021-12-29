require 'rubygems'

namespace :gem do
  desc "Build the rdf-n3-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build rdf-n3.gemspec && mv rdf-n3-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the rdf-n3-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/rdf-n3-#{File.read('VERSION').chomp}.gem"
  end
end

namespace :etc do
  ETC_FILES = %w{etc/n3.sxp}
  desc 'Remove generated files in etc'
  task :clean do
    %x(rm #{ETC_FILES.join(' ')})
  end

  desc 'Create versions of ebnf files in etc'
  task build: ETC_FILES
end

file "etc/n3.sxp" => "etc/n3.ebnf" do |t|
  %x{ebnf -o #{t.name} #{t.source}}
end

file 'etc/manifests.ttl' do
  %x{script/tc --write-manifests -o etc/manifests.ttl}
end

desc "Generate EARL report"
task :earl => 'etc/earl.html'

file 'etc/earl.ttl' => 'etc/doap.ttl' do
  %x{script/tc --earl -o etc/earl.ttl}
end

file 'etc/earl.jsonld' => %w(etc/earl.ttl etc/manifests.ttl etc/template.haml) do
  %x{(cd etc; earl-report --format json -o earl.jsonld earl.ttl)}
end

file 'etc/earl.html' => 'etc/earl.jsonld' do
  %x{(cd etc; earl-report --json --format html --template template.haml -o earl.html earl.jsonld)}
end
