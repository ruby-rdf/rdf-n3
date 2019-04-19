# RDF::N3 reader/writer and reasoner
Notation-3 reader/writer for [RDF.rb][RDF.rb] .

[![Gem Version](https://badge.fury.io/rb/rdf-n3.png)](https://badge.fury.io/rb/rdf-n3)
[![Build Status](https://travis-ci.org/ruby-rdf/rdf-n3.png?branch=master)](https://travis-ci.org/ruby-rdf/rdf-n3)

## Description
RDF::N3 is an Notation-3 parser for Ruby using the [RDF.rb][RDF.rb]  library suite. Also implements N3 Entailment.

Reader inspired from TimBL predictiveParser and Python librdf implementation.

## Turtle deprecated
Support for Turtle mime-types and specific format support has been deprecated from this gem,
as Turtle is now implemented using [RDF::Turtle][RDF::Turtle].

## Features
RDF::N3 parses [Notation-3][N3], [Turtle][Turtle] and [N-Triples][N-Triples] into statements or quads. It also performs reasoning and serializes to N3.

Install with `gem install rdf-n3`

## Limitations
* Support for Variables in Formulae. Existential variables are quantified to RDF::Node instances, Universals to RDF::Query::Variable, with the URI of the variable target used as the variable name.

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

### Reasoning
Experimental N3 reasoning is supported. Instantiate a reasoner from a dataset:

    RDF::N3::Reasoner.new do |reasoner|
      RDF::N3::Reader.open("etc/foaf.n3") {|reader| reasoner << reader}

       reader.each_statement do |statement|
         puts statement.inspect
       end
    end

Reasoning is performed by turning a repository containing formula and predicate operators into an executable set of operators (similar to the executable SPARQL Algebra). Reasoning adds statements to the base dataset, marked with `:inferred` (e.g. `statement.inferred?`). Predicate operators are defined from the following vocabularies:

* RDF List vocabulary <http://www.w3.org/2000/10/swap/list#>
  * list:append (not implemented yet - See {RDF::N3::Algebra::ListAppend})
  * list:in (not implemented yet - See {RDF::N3::Algebra::ListIn})
  * list:last (not implemented yet - See {RDF::N3::Algebra::ListLast})
  * list:member (not implemented yet - See {RDF::N3::Algebra::ListMember})
* RDF Log vocabulary <http://www.w3.org/2000/10/swap/log#>
  * log:conclusion (not implemented yet - See {RDF::N3::Algebra::LogConclusion})
  * log:conjunction (not implemented yet - See {RDF::N3::Algebra::LogConjunction})
  * log:equalTo (See {not implemented yet - RDF::N3::Algebra::LogEqualTo})
  * log:implies (See {RDF::N3::Algebra::LogImplies})
  * log:includes (not implemented yet - See {RDF::N3::Algebra::LogIncludes})
  * log:notEqualTo (not implemented yet - See {RDF::N3::Algebra::LogNotEqualTo})
  * log:notIncludes (not implemented yet - See {RDF::N3::Algebra::LogNotIncludes})
  * log:outputString (not implemented yet - See {RDF::N3::Algebra::LogOutputString})

N3 Formulae are introduced with the { statement-list } syntax. A given formula is assigned an RDF::Node instance, which is also used as the graph_name for RDF::Statement instances provided to RDF::N3::Reader#each_statement. For example, the following N3 generates the associated statements:

    @prefix x: <http://example.org/x-ns/#> .
    @prefix log: <http://www.w3.org/2000/10/swap/log#> .
    @prefix dc: <http://purl.org/dc/elements/1.1/#> .

    { [ x:firstname  "Ora" ] dc:wrote [ dc:title  "Moby Dick" ] } a log:falsehood .
  
when turned into an RDF Repository results in the following quads

    _:form <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/swap/log#falsehood> .
    _:moby <http://purl.org/dc/elements/1.1/#title> "Moby Dick" _:form .
    _:ora <http://purl.org/dc/elements/1.1/#wrote> _:moby _:form .
    _:ora <http://example.org/x-ns/#firstname> "Ora" _:form .

Reasoning uses a Notation3 Algebra, similar to [SPARQL S-Expressions](). This implementation considers formulae to be patterns, which may be asserted on statements made in the default graph, possibly loaded from a separate file. The logical relationships are reduced to algebraic operators. 

### Variables
N3 Variables are introduced with @forAll, @forSome, or ?x. Variables reference URIs described in formulae, typically defined in the default vocabulary (e.g., ":x"). Existential variables are replaced with an allocated RDF::Node instance. Universal variables are replaced with a RDF::Query::Variable instance. For example, the following N3 generates the associated statements:

    @forAll <#h>. @forSome <#g>. <#g> <#loves> <#h> .

results in:

    h = RDF::Query::Variable.new(<#h>)
    g = RDF::Node.new()
    RDF::Statement(f, <#loves>, h)

Note that the behavior of both existential and universal variables is not entirely in keeping with the [Team Submission][], and neither work quite like SPARQL variables. When used in the antecedent part of an implication, universal variables should behave much like SPARQL variables. This area is subject to a fair amount of change.

## Implementation Notes
The parser is driven through a rules table contained in lib/rdf/n3/reader/meta.rb. This includes
branch rules to indicate productions to be taken based on a current production. Terminals are denoted
through a set of regular expressions used to match each type of terminal.

The [meta.rb][file:lib/rdf/n3/reader/meta.rb] file is generated from lib/rdf/n3/reader/n3-selectors.n3
(taken from http://www.w3.org/2000/10/swap/grammar/n3-selectors.n3) which is the result of parsing
http://www.w3.org/2000/10/swap/grammar/n3.n3 (along with bnf-rules.n3) using cwm using the following command sequence:

    cwm n3.n3 bnf-rules.n3 --think --purge --data > n3-selectors.n3

[n3-selectors.n3][file:lib/rdf/n3/reader/n3-selectors.rb] is itself used to generate meta.rb using script/build_meta.

## Dependencies
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.0, >= 3.0.10)

## Documentation
Full documentation available on [RubyDoc.info](https://rubydoc.info/github/ruby-rdf/rdf-n3)

### Principle Classes
* {RDF::N3}
* {RDF::N3::Format}
* {RDF::N3::Reader}
* {RDF::N3::Reasoner}
* {RDF::N3::Writer}
* {RDF::N3::Algebra}
  * {RDF::N3::Algebra::Formula}
  * {RDF::N3::Algebra::ListAppend}
  * {RDF::N3::Algebra::ListIn}
  * {RDF::N3::Algebra::ListLast}
  * {RDF::N3::Algebra::ListMember}
  * {RDF::N3::Algebra::LogConclusion}
  * {RDF::N3::Algebra::LogConjunction}
  * {RDF::N3::Algebra::LogEqualTo}
  * {RDF::N3::Algebra::LogImplies}
  * {RDF::N3::Algebra::LogIncludes}
  * {RDF::N3::Algebra::LogNotEqualTo}
  * {RDF::N3::Algebra::LogNotIncludes}
  * {RDF::N3::Algebra::LogOutputString}

### Additional vocabularies
* {RDF::N3::Log}
* {RDF::N3::Rei}
* {RDF::N3::Crypto}
* {RDF::N3::List}
* {RDF::N3::Math}
* {RDF::N3::Str}
* {RDF::N3::Time}

## Resources
* [RDF.rb][RDF.rb]
* [Distiller](http://rdf.greggkellogg.net/distiller)
* [Documentation](https://rubydoc.info/github/ruby-rdf/rdf-n3/)
* [History](file:file.History.html)
* [Notation-3][N3]
* [N3 Primer](https://www.w3.org/2000/10/swap/Primer.html)
* [N3 Reification](https://www.w3.org/DesignIssues/Reify.html)
* [Turtle][Turtle]
* [W3C SWAP Test suite](https://www.w3.org/2000/10/swap/test/README.html)
* [W3C Turtle Test suite](https://www.w3.org/2001/sw/DataAccess/df1/tests/README.txt)
* [N-Triples][N-Triples]

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributors
* [Nicholas Humfrey](https://github.com/njh) - <https://njh.me/>

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
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

## Feedback
* <gregg@greggkellogg.net>
* <https://rubygems.org/gem/rdf-n3>
* <https://github.com/ruby-rdf/rdf-n3>
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

[RDF.rb]:       https://ruby-rdf.github.com/rdf
[RDF::Turtle]:  https://ruby-rdf.github.com/rdf-turtle/
[N3]:           https://www.w3.org/DesignIssues/Notation3.html "Notation-3"
[Team Submission]: https://www.w3.org/TeamSubmission/n3/
[Turtle]:       https://www.w3.org/TR/turtle/
[N-Triples]:    https://www.w3.org/TR/n-triples/
[YARD]:         https://yardoc.org/
[YARD-GS]:      https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:          https://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[SPARQL S-Expressions]: https://jena.apache.org/documentation/notes/sse.html
