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
  ETC_FILES = %w{etc/n3.sxp etc/n3.peg.sxp}
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

file "etc/n3.peg.sxp" => "etc/n3.ebnf" do |t|
  %x{ebnf --peg -o #{t.name} #{t.source}}
end

task :meta => %w{lib/rdf/n3/meta.rb}

file "lib/rdf/n3/meta.rb" => "etc/n3.ebnf" do
  %x(ebnf --peg -f rb --mod-name RDF::N3::Meta -o lib/rdf/n3/meta.rb etc/n3.ebnf)
end
