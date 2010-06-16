require File.dirname(__FILE__) + '/../lib/rdf_objects/changeset'
require 'rexml/document'
include RDFObject
describe "An RDFObject ChangeSet" do
  before(:each) do
    @resource = Resource.new('http://example.org/ex/1234')
    @resource.relate("[rdf:type]","[foaf:Person]")
    foaf_name = RDF::Literal.new("John Doe")
    foaf_name.language = :en
    @resource.assert("[foaf:name]", foaf_name)
    @resource.relate("[foaf:pastProject]","http://dbtune.org/musicbrainz/resource/artist/ddd553d4-977e-416c-8f57-e4b72c0fc746")
    @resource.relate("[foaf:homepage]","http://www.theejohndoe.com/")
  end
  
  it "should set a ChangeSet Curie prefix" do
    cs =  Curie.parse "[cs:removal]"
    cs.should_not be_nil
    cs.should eql("http://purl.org/vocab/changeset/schema#removal")
  end
  
  it "should be an RDFObject::BlankNode" do
    changeset = ChangeSet.new(@resource)
    changeset.should be_kind_of(RDFObject::BlankNode)
  end
  
  it "should set the default properties on initialization" do
    changeset = ChangeSet.new(@resource)
    changeset["http://purl.org/vocab/changeset/schema#subjectOfChange"].uri.should eql(@resource.uri)
    changeset.rdf['type'].uri.should eql("http://purl.org/vocab/changeset/schema#ChangeSet")
  end
  
  it "should model removing triples" do
    changeset = ChangeSet.new(@resource)    
    changeset.remove_statement("[foaf:homepage]", "http://www.theejohndoe.com/")
    changeset.removals.length.should ==(1)
    changeset.additions.length.should ==(0)
    stmt = changeset.removals.first
    stmt.should be_kind_of(RDFObject::BlankNode)
    stmt.rdf['type'].should_not be_nil
    stmt.rdf['type'].uri.should eql("http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement")
    stmt.assertions.keys.length.should ==(4)
    stmt.rdf['subject'].should_not be_nil
    stmt.rdf['subject'].should be_kind_of(RDFObject::ResourceReference)    
    stmt.rdf['subject'].uri.should eql(@resource.uri)      
    stmt.rdf['predicate'].should_not be_nil
    stmt.rdf['predicate'].uri.should eql("http://xmlns.com/foaf/0.1/homepage")    
    stmt.rdf['predicate'].should be_kind_of(RDFObject::ResourceReference)    
    stmt.rdf['object'].should be_kind_of(RDF::Literal)
    stmt.rdf['object'].value.should eql("http://www.theejohndoe.com/")
  end

  it "should model adding triples" do
    changeset = ChangeSet.new(@resource)    
    changeset.add_statement("http://www.w3.org/2002/07/owl#sameAs", Resource.new("http://dbpedia.org/resource/John_Doe_%28musician%29"))
    changeset.removals.length.should ==(0)
    changeset.additions.length.should ==(1)
    stmt = changeset.additions.first
    stmt.should be_kind_of(RDFObject::BlankNode)
    stmt.rdf['type'].should_not be_nil
    stmt.rdf['type'].uri.should eql("http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement")
    stmt.assertions.keys.length.should ==(4)
    stmt.rdf['subject'].should_not be_nil
    stmt.rdf['subject'].should be_kind_of(RDFObject::ResourceReference)  
    stmt.rdf['subject'].uri.should eql(@resource.uri)  
    stmt.rdf['predicate'].should_not be_nil
    stmt.rdf['predicate'].should be_kind_of(RDFObject::ResourceReference)    
    stmt.rdf['predicate'].uri.should eql("http://www.w3.org/2002/07/owl#sameAs")
    stmt.rdf['object'].should_not be_nil
    stmt.rdf['object'].should be_kind_of(RDFObject::ResourceReference)     
    stmt.rdf['object'].uri.should eql("http://dbpedia.org/resource/John_Doe_%28musician%29")   
  end 
  
  it "should set the change reason" do
    changeset = ChangeSet.new(@resource)    
    changeset.reason = "Typpo"    
    changeset.cs['changeReason'].should_not be_nil
    changeset.cs['changeReason'].value.should eql("Typpo")
  end
  
  it "should only ever have one change reason" do
    changeset = ChangeSet.new(@resource)    
    changeset.reason = "Typpo"    
    changeset.reason = "Typo"
    changeset.cs['changeReason'].should be_kind_of(RDF::Literal)
    changeset.cs['changeReason'].value.should eql("Typo")
  end  
  
  it "should set the creator name" do
    changeset = ChangeSet.new(@resource)    
    changeset.creator_name = "John Doe"    
    changeset.cs['creatorName'].should_not be_nil
    changeset.cs['creatorName'].value.should eql("John Doe")
  end
  
  it "should only ever have one creator name" do
    changeset = ChangeSet.new(@resource)    
    changeset.creator_name = "John Doe"    
    changeset.creator_name = "Jane Doe"
    changeset.cs['creatorName'].should be_kind_of(RDF::Literal)
    changeset.cs['creatorName'].value.should eql("Jane Doe")
  end  
  
  it "should allow multiple assertions to be removed/added at once" do
    @resource.assert("http://www.w3.org/2004/02/skos/core#prefLabel", "John Nommensen Duchac")
    @resource.assert("http://www.w3.org/2004/02/skos/core#prefLabel", "Doe, John")
    changeset = ChangeSet.new(@resource)    
    bad_name = {"http://www.w3.org/2004/02/skos/core#prefLabel" => @resource["http://www.w3.org/2004/02/skos/core#prefLabel"]}
    fixed_name = {"http://www.w3.org/2004/02/skos/core#prefLabel" => "John Doe"}
    changeset.replace_statements(bad_name, fixed_name)
    changeset.removals.length.should ==(2)
    changeset.additions.length.should ==(1)    
  end
  
  it "should remove all assertions by predicate URI" do
    @resource.assert("[foaf:name]", "John Nommensen Duchac")
    changeset = ChangeSet.new(@resource)    
    changeset.clear_predicate("[foaf:name]")
    changeset.removals.length.should ==(2)
  end
  
  it "should be able to delete all assertions associated with a resource" do
    changeset = ChangeSet.new(@resource)    
    changeset.delete_all
    changeset.additions.length.should ==(0)
    changeset.removals.length.should ==(4)
  end
  
  it "should serialize an RDF/XML document" do
    changeset = ChangeSet.new(@resource)    
    changeset.delete_all
    changeset.to_xml.should be_kind_of(String)
    lambda { REXML::Document.new(changeset.to_xml)}.should_not raise_error
    lambda { Parser.parse(changeset.to_xml)}.should_not raise_error    
    collection = Parser.parse(changeset.to_xml)
    cs = collection[changeset.uri]
    cs.cs['removal'].length.should eql(changeset.removals.length)
    cs.cs['addition'].should be_nil
    changeset.additions.length.should ==(0)   
  end
end
