require 'rubygems'
require 'rdf_objects'
require 'uuid'
module RDFObject
  Curie.add_prefixes! :cs=> "http://purl.org/vocab/changeset/schema#"      
  
  require File.dirname(__FILE__) + '/changeset/changeset' 
end