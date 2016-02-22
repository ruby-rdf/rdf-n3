# RDF::N3 reader/writer
Notation-3 reader/writer for [RDF.rb][RDF.rb] .

[![Gem Version](https://badge.fury.io/rb/rdf-n3.png)](http://badge.fury.io/rb/rdf-n3)
[![Build Status](https://travis-ci.org/ruby-rdf/rdf-n3.png?branch=master)](http://travis-ci.org/ruby-rdf/rdf-n3)

## Description
RDF::N3 is an Notation-3 parser for Ruby using the [RDF.rb][RDF.rb]  library suite.

Reader inspired from TimBL predictiveParser and Python librdf implementation.

## Turtle deprecated
Support for Turtle mime-types and specific format support has been deprecated from this gem,
as Turtle is now implemented using [RDF::Turtle][RDF::Turtle].

## Features
RDF::N3 parses [Notation-3][N3], [Turtle][Turtle] and [N-Triples][N-Triples] into statements or triples. It also serializes to Turtle.

Install with `gem install rdf-n3`

## Limitations
* Full support of Unicode input requires Ruby version 2.0 or greater.
* Support for Variables in Formulae dependent on underlying repository. Existential variables are quantified to RDF::Node instances, Universals to RDF::Query::Variable, with the URI of the variable target used as the variable name.
* No support for N3 Reification. If there were, it would be through a :reify option to the reader.

## Usage
Instantiate a reader from a local file:

    RDF::N3::Reader.open("etc/foaf.n3") do |reader|
       reader.each_statement do |statement|
         puts statement.inspect
       end
    end

Define `@base` and `@prefix` definitions, and use for serialization using `:base_uri` an `:prefixes` options

Write a graph to a file:

    RDF::N3::Writer.open("etc/test.n3") do |writer|
       writer << graph
    end

### Formulae
N3 Formulae are introduced with the { statement-list } syntax. A given formula is assigned an RDF::Node instance, which is also used as the graph_name for RDF::Statement instances provided to RDF::N3::Reader#each_statement. For example, the following N3 generates the associated statements:

    { [ x:firstname  "Ora" ] dc:wrote [ dc:title  "Moby Dick" ] } a n3:falsehood .
  
results in

    f = RDF::Node.new
    s = RDF::Node.new
    o = RDF::Node.new
    RDF::Statement(f, rdf:type n3:falsehood)
    RDF::Statement(s, x:firstname, "Ora", graph_name: f)
    RDF::Statement(s, dc:wrote, o, graph_name: f)
    RDF::Statement(o, dc:title, "Moby Dick", graph_name: f)

### Variables
N3 Variables are introduced with @forAll, @forEach, or ?x. Variables reference URIs described in formulae, typically defined in the default vocabulary (e.g., ":x"). Existential variables are replaced with an allocated RDF::Node instance. Universal variables are replaced with a RDF::Query::Variable instance. For example, the following N3 generates the associated statements:

    @forAll <#h>. @forSome <#g>. <#g> <#loves> <#h> .

results in:

    h = RDF::Query::Variable.new(<#h>)
    g = RDF::Node.new()
    RDF::Statement(f, <#loves>, h)

## Implementation Notes
The parser is driven through a rules table contained in lib/rdf/n3/reader/meta.rb. This includes
branch rules to indicate productions to be taken based on a current production. Terminals are denoted
through a set of regular expressions used to match each type of terminal.

The [meta.rb][file:lib/rdf/n3/reader/meta.rb] file is generated from lib/rdf/n3/reader/n3-selectors.n3
(taken from http://www.w3.org/2000/10/swap/grammar/n3-selectors.n3) which is the result of parsing
http://www.w3.org/2000/10/swap/grammar/n3.n3 (along with bnf-rules.n3) using cwm using the following command sequence:

    cwm n3.n3 bnf-rules.n3 --think --purge --data > n3-selectors.n3

[n3-selectors.n3][file:lib/rdf/n3/reader/n3-selectors.rb] is itself used to generate meta.rb using script/build_meta.

## TODO
* Generate Formulae and solutions using BGP and SPARQL CONSTRUCT mechanisms
* Create equivalent to `--think` to iterate on solutions.

## Dependencies
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 2.0)

## Documentation
Full documentation available on [RubyDoc.info](http://rubydoc.info/github/ruby-rdf/rdf-n3/frames)

### Principle Classes
* {RDF::N3}
* {RDF::N3::Format}
* {RDF::N3::Reader}
* {RDF::N3::Writer}

### Additional vocabularies
* {RDF::LOG}
* {RDF::REI}

### Patches
* `Array`
* `RDF::List`

## Resources
* [RDF.rb][RDF.rb]
* [Distiller](http://rdf.greggkellogg.net/distiller)
* [Documentation](http://rubydoc.info/github/ruby-rdf/rdf-n3/master/frames)
* [History](file:file.History.html)
* [Notation-3][N3]
* [N3 Primer](http://www.w3.org/2000/10/swap/Primer.html)
* [N3 Reification](http://www.w3.org/DesignIssues/Reify.html)
* [Turtle][Turtle]
* [W3C SWAP Test suite](http://www.w3.org/2000/10/swap/test/README.html)
* [W3C Turtle Test suite](http://www.w3.org/2001/sw/DataAccess/df1/tests/README.txt)
* [N-Triples][N-Triples]

## Author
* [Gregg Kellogg](http://github.com/gkellogg) - <http://greggkellogg.net/>

## Contributors
* [Nicholas Humfrey](http://github.com/njh) - <http://njh.me/>

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

## Feedback
* <gregg@greggkellogg.net>
* <http://rubygems.org/gem/rdf-n3>
* <http://github.com/ruby-rdf/rdf-n3>
* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

[RDF.rb]:       http://ruby-rdf.github.com/rdf
[RDF::Turtle]:  http://ruby-rdf.github.com/rdf-turtle/
[N3]:           http://www.w3.org/DesignIssues/Notation3.html "Notation-3"
[Turtle]:       http://www.w3.org/TR/turtle/
[N-Triples]:    http://www.w3.org/TR/n-triples/
[YARD]:         http://yardoc.org/
[YARD-GS]:      http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:          http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
