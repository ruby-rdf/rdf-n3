require 'rdf/n3/patches/graph_properties'
module RDF
  class Graph
    # Returns ordered rdf:_n objects or rdf:first, rdf:rest for a given subject
    def seq(subject)
      props = properties(subject)
      rdf_type = (props[RDF.type.to_s] || []).map {|t| t.to_s}

      #puts "seq; #{rdf_type} #{rdf_type - [RDF.Seq, RDF.Bag, RDF.Alt]}"
      if !(rdf_type - [RDF.Seq, RDF.Bag, RDF.Alt]).empty?
        props.keys.select {|k| k.match(/#{RDF._}(\d)$/)}.
          sort_by {|i| i.sub(RDF._.to_s, "").to_i}.
          map {|key| props[key]}.
          flatten
      elsif !self.query(:subject => subject, :predicate => RDF.first).empty?
        # N3-style first/rest chain
        list = []
        while subject != RDF.nil
          props = properties(subject)
          f = props[RDF.first.to_s]
          if f.to_s.empty? || f.first == RDF.nil
            subject = RDF.nil
          else
            list += f
            subject = props[RDF.rest.to_s].first
          end
        end
        list
      else
        []
      end
    end
  end
end