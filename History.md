0.3.1.3
-----
* Normalize language tags to lower case (only when canonicalizing). SPARQL specs expect the reader
  to not screw with the language case for equivalence tests.

0.3.1.2
-----
* Normalize language tags to lower case.

0.3.1.1
-----
* Assert formats for :ttl, :turtle, and :notation3 in addition to :n3

0.3.1
-----
* Add application/turtle, application/x-turtle, text/rdf+n3 and application/rdf+n3 as mime types
  matching this format, even though only text/turtle and text/n3 are valid.

0.3.0
-----
* New Predictive-Parser based N3 Reader, substantially faster than previous Treetop-based parser
* RDF.rb 0.3.0 compatibility updates
  * Remove literal_normalization and qname_hacks, add back uri_hacks (until 0.3.0)
  * Use nil for default namespace
  * In Writer
    * Use only :prefixes for creating QNames.
    * Add :standard_prefixes and :default_namespace options.
    * Use """ for multi-line quotes, or anything including escaped characters
  * In Reader
    * URI canonicalization and validation.
    * Added :canonicalize, and :intern options.
    * Added #prefixes method returning a hash of prefix definitions.
    * Change :strict option to :validate.
    * Add check to ensure that predicates are not literals, it's not legal in any RDF variant.
* RSpec 2 compatibility

0.2.3
-----
* In Writer, set @base_uri not @base, as :base_uri is an attribute.
* Relativize URLs without matching as regexp.
* Allow mixed case literal languages.
* Improve N3 Unicode support for Ruby 1.9
* Improve Turtle/N3 Writer to use unescaped and qname'd values

0.2.2
-----
* Ruby 1.9.2 compatibility
* Added script/tc to run test cases
* Fixed RDF.to_s != RDF.to_uri.to_s in writer, it worke for every other vocabulary
* Handle XMLLiteral when value is a Nokogiri node set.
* Simplify process_uri by not having a special case for ^# type URIs.
* Unescape values when creating URIs.
* URI normalization isn't required for N3, so removed.
* Added Reader#rewind and #close as stubs because document is parsed on initialize and input is closed.

0.2.1
-----
* Compatible with RDF.rb 0.2.1

0.0.3
-----
* Replace require against rdf/rdfxml/patches/* with rdf/n3/patches/*

0.0.2
-----
* N3 parsing and Turtle serialization substantially complete.
  * A little more work needed on some tests and some lingering issues in RDF.rb to be resolved.
* Added script/console and script/parse
* Updates to reader to bring it in line with other readers. Implement uri() and ns() as helper functions for constructing URIs.
* Literal_normalization to override RDF::Literal.initialize and create Literal#valid?
* rdf_escape Literals when serializing via to_s
* Remove trailing "#" from URIs when normalizing.

0.0.1
-----
* First port from RdfContext version 0.5.4
