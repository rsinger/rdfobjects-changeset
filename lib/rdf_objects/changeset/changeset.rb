module RDFObject
  
  class ChangeSet < BlankNode
    attr_reader :resource, :additions, :removals
    def initialize(resource, versioned=false)
      @resource = resource
      @versioned = versioned
      @additions = []
      @removals = []
      super(UUID.generate)

      assert("[cs:createdDate]", Time.now)
      relate("[rdf:type]", "[cs:ChangeSet]")
      relate("[cs:subjectOfChange]", @resource.uri)      
    end
    
    def reason=(reason_note)
      self.cs['changeReason'] = nil if self.cs['changeReason']
      assert("[cs:changeReason]", reason_note)
    end
    
    def creator_name=(name)
      self.cs['creatorName'] = nil if self.cs['creatorName']      
      assert("[cs:creatorName]", name)
    end    
    
    def delete_all()
      @resource.assertions.each_pair do |predicate, objects|
        [*objects].each do |object|
          next unless object
          @removals <<  create_statement(predicate, object)
        end
      end 
    end
    
    def add_statement(predicate, object)
      @additions << create_statement(predicate, object)
    end
    
    def remove_statement(predicate, object)
      @removals << create_statement(predicate, object)
    end
    
    def replace_statements(from, to=nil)
      from.each_pair do |pred, objects|
        [*objects].each do |o|
          next unless o
          @removals << create_statement(pred, o)
        end
      end
      if to and to.is_a?(Hash) and !to.empty?
        to.each_pair do |pred, objects|
          [*objects].each do |o|
            next unless o
            @additions << create_statement(pred, o)
          end
        end
      end
    end   
    
    def clear_predicate(uri) 
      [*@resource[uri]].each do |object|
        next unless object
        @removals << create_statement(uri, object)
      end
    end
    
    def create_statement(predicate, object)
      stmt = BlankNode.new(UUID.generate)
      stmt.relate("[rdf:type]", "[rdf:Statement]")
      stmt.relate("[rdf:subject]", @resource.uri)
      stmt.relate("[rdf:predicate]", predicate)      
      stmt.assert("[rdf:object]", object)
      stmt      
    end
    
    def rdf_description_block(depth=0)
      rdf = "<rdf:Description #{xml_subject_attribute}>"
      namespaces = {}
      Curie.get_mappings.each_pair do |key, value|
        if self.respond_to?(key.to_sym)
          self.send(key.to_sym).each_pair do | predicate, objects |
            [*objects].each do | object |
              rdf << "<#{key}:#{predicate}"
              namespaces["xmlns:#{key}"] = "#{Curie.parse("[#{key}:]")}"
              if object.is_a?(RDFObject::ResourceReference) || object.is_a?(RDFObject::BlankNode)
                if depth == 0
                  rdf << " #{object.xml_object_attribute} />"
                else
                  rdf << ">"                  
                  ns, rdf_data = object.rdf_description_block(depth-1)
                  namespaces.merge!(ns)
                  rdf << rdf_data
                  rdf << "</#{key}:#{predicate}>"
                end
              else
                object = RDF::Literal.new(object) unless object.is_a?(RDF::Literal)
                if object.language
                  rdf << " xml:lang=\"#{object.language}\""
                end
                if object.datatype
                  rdf << " rdf:datatype=\"#{object.datatype}\""
                end
                rdf << ">#{CGI.escapeHTML(object.value)}</#{key}:#{predicate}>"
              end
            end
          end
        end
        if value == "http://purl.org/vocab/changeset/schema#"
          @removals.each do |removal|
            rdf << "<#{key}:removal>"
            ns, rdf_data = removal.rdf_description_block
            namespaces.merge!(ns)
            rdf << rdf_data            
            rdf << "</#{key}:removal>"
          end
          @additions.each do |addition|
            rdf << "<#{key}:addition>"
            ns, rdf_data = addition.rdf_description_block
            namespaces.merge!(ns)
            rdf << rdf_data
            rdf << "</#{key}:addition>"
          end                      
        end
      end
      
      rdf << "</rdf:Description>"
      [namespaces, rdf]
    end    
  end
end