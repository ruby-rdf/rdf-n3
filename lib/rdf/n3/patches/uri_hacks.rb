module RDF
  class URI
    ##
    # Joins several URIs together.
    #
    # @param  [Array<String, URI, #to_str>] uris
    # @return [URI]
    #
    # GK -- don't add a "/" at the end of URIs, due to rdfcore/xmlbase/test002.rdf
    def join(*uris)
      result = @uri
      uris.each do |uri|
#        result.path += '/' unless result.path.match(/[\#\/]$/) || uri.to_s[0..0] == "#"
        result = result.join(uri)
      end
      self.class.new(result)
    end
    
    # From http://www.w3.org/TR/2004/REC-rdf-concepts-20040210/#section-Graph-URIref
    #
    # A URI Reference within an RDF graph is a Unicode string that:
    # * does not contain any control characters ( #x00 - #x1F, #x7F-#x9F)
    # * and would produce a valid URI character sequence (per RFC2396 [URI], sections 2.1) representing an absolute URI with optional fragment identifier when subjected to the encoding described below.
    #
    # The encoding consists of:
    # 1. encoding the Unicode string as UTF-8 [RFC-2279], giving a sequence of octet values.
    # 2. %-escaping octets that do not correspond to permitted US-ASCII characters.
  end
end