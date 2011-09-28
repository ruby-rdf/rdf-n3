module RDF::N3
  ##
  # RDFa format specification.
  #
  # @example Obtaining an Notation3 format class
  #     RDF::Format.for(:n3)            #=> RDF::N3::Format
  #     RDF::Format.for("etc/foaf.n3")
  #     RDF::Format.for(:file_name      => "etc/foaf.n3")
  #     RDF::Format.for(:file_extension => "n3")
  #     RDF::Format.for(:content_type   => "text/n3")
  #
  # @example Obtaining serialization format MIME types
  #     RDF::Format.content_types      #=> {"text/n3")" => [RDF::N3::Format]}
  #
  # @example Obtaining serialization format file extension mappings
  #     RDF::Format.file_extensions    #=> {:n3 => "text/n3"}
  #
  # @see http://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_type     'text/n3',             :extension => :n3
    content_type     'text/rdf+n3',         :extension => :n3
    content_type     'application/rdf+n3',  :extension => :n3
    content_encoding 'utf-8'

    reader { RDF::N3::Reader }
    writer { RDF::N3::Writer }

    ##
    # Sample detection to see if it matches N3 (or N-Triples or Turtle)
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement
    # a matcher sufficient to detect probably format matches, including disambiguating
    # between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      !!sample.match(%r(
        (?:@(base|prefix|keywords)) |                                   # N3 keywords
        "{3} |                                                          # Multi-line quotes
        "[^"]*"^^ | "[^"]*"@ |                                          # Typed/Language literals
        (?:
          (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:"[^"]*"))\s*[,;]) ||
          (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:"[^"]*"))){3}
        )
      )mx) && !(
        sample.match(%r(<(?:\/|html|rdf))i) ||                          # HTML, RDF/XML
        sample.match(%r(^(?:\s*<[^>]*>){4}.*\.\s*$)) ||                 # N-Quads
        sample.match(%r("@(context|subject|iri)"))                      # JSON-LD
      )
    end
  end
  
  # Alias for N3 format
  #
  # This allows the following:
  #
  # @example Obtaining an Notation3 format class
  #     RDF::Format.for(:ttl)         #=> RDF::N3::Notation3
  #     RDF::Format.for(:ttl).reader  #=> RDF::N3::Reader
  #     RDF::Format.for(:ttl).writer  #=> RDF::N3::Writer
  class Notation3 < RDF::Format
    reader { RDF::N3::Reader }
    writer { RDF::N3::Writer }
  end
end
