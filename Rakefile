require "rake"

require "spec/rake/spectask"



desc "Run all specs"

Spec::Rake::SpecTask.new("specs") do |t|

  t.spec_files = FileList["specs/*.rb"]

end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rdfobjects-changeset"
    gemspec.summary = "An extension to RDFObjects to more easily work with RDF ChangeSets."
    gemspec.description = "An extension to RDFObjects to more easily work with RDF ChangeSets:  http://n2.talis.com/wiki/Changesets"
    gemspec.email = "rossfsinger@gmail.com"
    gemspec.homepage = "http://github.com/rsinger/rdfobjects-changesets"
    gemspec.authors = ["Ross Singer"]
    gemspec.add_dependency('rdfobjects')
    gemspec.add_dependency('uuid')
    gemspec.files = Dir.glob("{lib,spec}/**/*") + ["README", "LICENSE"]
    gemspec.require_path = 'lib'    
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

