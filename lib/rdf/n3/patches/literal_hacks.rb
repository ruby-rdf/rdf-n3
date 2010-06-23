module RDF
  class Literal
    # Support for XML Literals
    # Is this an XMLLiteral?
    def xmlliteral?
      datatype == RDF['XMLLiteral']
    end
    
    def anonymous?; false; end unless respond_to?(:anonymous?)
    
    ##
    # Returns a string representation of this literal.
    #
    # @return [String]
    def to_s
      quoted = value # FIXME
      output = "\"#{quoted.to_s.rdf_escape}\""
      output << "@#{language}" if has_language? && !has_datatype?
      output << "^^<#{datatype}>" if has_datatype?
      output
    end
  end
end