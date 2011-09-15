## 0.3.6
* Update for RDF.rb 0.3.4
* Added format detection.

## 0.3.5
* Use RDF::List for reading and writing lists.
* Performance improvements.
* Writer whitespace and property ordering improvements.
* Remove explicit Turtle support in Reader.

## 0.3.4.1
* In Reader, if no base\_uri is used, make sure that @prefix : <#> is generated, not @prefix : <>.
* In Writer, fix bug when trying to use `:standard\_prefixes` option.

## 0.3.4
* Reader accepts 1.0E1 in addition to 1.0e1 (case-insensitive match on exponent).
* Writer was not outputting xsd prefix if it was only used in a literal datatype.
* Use bare representations of xsd:integer, xsd:boolean, xsd:double, and xsd:decimal.
* Implement literal canonicalization (on option) in writer.

## 0.3.3.1
* Fixed bug in writer when given a base URI.

## 0.3.3
* Update dependencies to RDF.rb 0.3.3
* Update specs to use open-uri-cached and Spira; no longer directly include W3C test cases.
* Use Bundler when running specs.
* Only output prefix definitions used in serialization.
* Fixed stack overflow in regular expression when matching long multi-line literals.
* Fixed bug (issue 14) where illegal QNames were generated in writer.

## 0.3.2
* Skipped

## 0.3.1.3
* Normalize language tags to lower case (only when canonicalizing). SPARQL specs expect the reader
  to not screw with the language case for equivalence tests.

## 0.3.1.2
* Normalize language tags to lower case.

## 0.3.1.1
* Assert formats for :ttl, :turtle, and :notation3 in addition to :n3

## 0.3.1
* Add application/turtle, application/x-turtle, text/rdf+n3 and application/rdf+n3 as mime types
  matching this format, even though only text/turtle and text/n3 are valid.

## 0.3.0
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

## 0.2.3
* In Writer, set @base_uri not @base, as :base_uri is an attribute.
* Relativize URLs without matching as regexp.
* Allow mixed case literal languages.
* Improve N3 Unicode support for Ruby 1.9
* Improve Turtle/N3 Writer to use unescaped and qname'd values

## 0.2.2
* Ruby 1.9.2 compatibility
* Added script/tc to run test cases
* Fixed RDF.to_s != RDF.to_uri.to_s in writer, it worke for every other vocabulary
* Handle XMLLiteral when value is a Nokogiri node set.
* Simplify process_uri by not having a special case for ^# type URIs.
* Unescape values when creating URIs.
* URI normalization isn't required for N3, so removed.
* Added Reader#rewind and #close as stubs because document is parsed on initialize and input is closed.

## 0.2.1
* Compatible with RDF.rb 0.2.1

## 0.0.3
* Replace require against rdf/rdfxml/patches/* with rdf/n3/patches/*

## 0.0.2
* N3 parsing and Turtle serialization substantially complete.
  * A little more work needed on some tests and some lingering issues in RDF.rb to be resolved.
* Added script/console and script/parse
* Updates to reader to bring it in line with other readers. Implement uri() and ns() as helper functions for constructing URIs.
* Literal_normalization to override RDF::Literal.initialize and create Literal#valid?
* rdf_escape Literals when serializing via to_s
* Remove trailing "#" from URIs when normalizing.

## 0.0.1
* First port from RdfContext version 0.5.4
