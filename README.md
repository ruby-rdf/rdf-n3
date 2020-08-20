# RDF::N3 reader/writer and reasoner
Notation-3 reader/writer for [RDF.rb][RDF.rb] .

[![Gem Version](https://badge.fury.io/rb/rdf-n3.png)](https://badge.fury.io/rb/rdf-n3)
[![Build Status](https://travis-ci.org/ruby-rdf/rdf-n3.png?branch=master)](https://travis-ci.org/ruby-rdf/rdf-n3)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-n3/badge.svg)](https://coveralls.io/r/ruby-rdf/rdf-n3)

## Description
RDF::N3 is an Notation-3 parser and reasoner for Ruby using the [RDF.rb][RDF.rb] library suite.

Reader inspired from TimBL predictiveParser and Python librdf implementation.

## Uses CG Specification
This version tracks the [W3C N3 Community Group][] [Specification][N3] which has incompatibilities with the [Team Submission][] version. Notably:

* The `@keywords` declaration is removed, and most form of `@` keywords (e.g., `@is`, `@has`, `@true`) are no longer supported.
* Terminals adhere closely to their counterparts in [Turtle][].
* The modifier `<-` is introduced as a synonym for `is ... of`.
* The SPARQL `BASE` and `PREFIX` declarations are supported.

This brings N3 closer to compatibility with Turtle.

## Features
RDF::N3 parses [Notation-3][N3], [Turtle][] and [N-Triples][] into statements or quads. It also performs reasoning and serializes to N3.

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

Reasoning is discussed in the [Design Issues][] document.

#### RDF List vocabulary <http://www.w3.org/2000/10/swap/list#>

  * `list:append` (not implemented yet - See {RDF::N3::Algebra::List::Append})
  * `list:in` (See {RDF::N3::Algebra::List::In})
  * `list:last` (See {RDF::N3::Algebra::List::Last})
  * `list:member` (See {RDF::N3::Algebra::List::Member})

#### RDF Log vocabulary <http://www.w3.org/2000/10/swap/log#>

  * `log:conclusion` (not implemented yet - See {RDF::N3::Algebra::Log::Conclusion})
  * `log:conjunction` (not implemented yet - See {RDF::N3::Algebra::Log::Conjunction})
  * `log:equalTo` (See {RDF::N3::Algebra::Log::EqualTo})
  * `log:implies` (See {RDF::N3::Algebra::Log::Implies})
  * `log:includes` (See {RDF::N3::Algebra::Log::Includes})
  * `log:notEqualTo` (not implemented yet - See {RDF::N3::Algebra::Log::NotEqualTo})
  * `log:notIncludes` (not implemented yet - See {RDF::N3::Algebra::Log::NotIncludes})
  * `log:outputString` (not implemented yet - See {RDF::N3::Algebra::Log::OutputString})

#### RDF String vocabulary <http://www.w3.org/2000/10/swap/str#>

  * `string:concatenation` (See {RDF::N3::Algebra::Str::Concatenation})
  * `string:contains` (See {SPARQL::Algebra::Operator::Contains})
  * `string:containsIgnoringCase` (See {RDF::N3::Algebra::Str::ContainsIgnoringCase})
  * `string:endsWith` (See {SPARQL::Algebra::Operator::StrEnds})
  * `string:equalIgnoringCase` (See {RDF::N3::Algebra::Str::EqualIgnoringCase})
  * `string:format` (See {RDF::N3::Algebra::Str::Format})
  * `string:greaterThan` (See {SPARQL::Algebra::Operator::GreaterThan})
  * `string:lessThan` (See {SPARQL::Algebra::Operator::LessThan})
  * `string:matches` (See {SPARQL::Algebra::Operator::Regex})
  * `string:notEqualIgnoringCase` (See {RDF::N3::Algebra::Str::NotEqualIgnoringCase})
  * `string:notGreaterThan` (See {SPARQL::Algebra::Operator::LessThanOrEqual})
  * `string:notLessThan` (See {SPARQL::Algebra::Operator::GreaterThanOrEqual})
  * `string:notMatches` (See {RDF::N3::Algebra::Str::NotMatches})
  * `string:replace` (See {RDF::N3::Algebra::Str::Replace})
  * `string:scrape` (See {RDF::N3::Algebra::Str::Scrape})
  * `string:startsWith` (See {SPARQL::Algebra::Operator::StrStarts})

### Formulae

N3 Formulae are introduced with the `{ statement-list }` syntax. A given formula is assigned an `RDF::Node` instance, which is also used as the graph_name for `RDF::Statement` instances provided to `RDF::N3::Reader#each_statement`. For example, the following N3 generates the associated statements:

    @prefix x: <http://example.org/x-ns/#> .
    @prefix log: <http://www.w3.org/2000/10/swap/log#> .
    @prefix dc: <http://purl.org/dc/elements/1.1/#> .

    { [ x:firstname  "Ora" ] dc:wrote [ dc:title  "Moby Dick" ] } a log:falsehood .
  
when turned into an RDF Repository results in the following quads

    _:form <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/swap/log#falsehood> .
    _:moby <http://purl.org/dc/elements/1.1/#title> "Moby Dick" _:form .
    _:ora <http://purl.org/dc/elements/1.1/#wrote> _:moby _:form .
    _:ora <http://example.org/x-ns/#firstname> "Ora" _:form .

Reasoning uses a Notation3 Algebra, similar to [SPARQL S-Expressions][]. This implementation considers formulae to be patterns, which may be asserted on statements made in the default graph, possibly loaded from a separate file. The logical relationships are reduced to algebraic operators. 

### Variables
N3 Variables are introduced with `@forAll`, `@forSome`, or `?x`. Variables reference URIs described in formulae, typically defined in the default vocabulary (e.g., `":x"`). Existential variables are replaced with an allocated `RDF::Node` instance. Universal variables are replaced with a `RDF::Query::Variable` instance. For example, the following N3 generates the associated statements:

    @forAll <#h>. @forSome <#g>. <#g> <#loves> <#h> .

results in:

    h = RDF::Query::Variable.new(<#h>)
    g = RDF::Node.new()
    RDF::Statement(f, <#loves>, h)

Note that the behavior of both existential and universal variables is not entirely in keeping with the [Team Submission][], and neither work quite like SPARQL variables. When used in the antecedent part of an implication, universal variables should behave much like SPARQL variables. This area is subject to a fair amount of change.

### Query
Formulae are typically used to query the knowledge-base, which is set from the base-formula/default graph. A formula is composed of both constant statements, and variable statements. When running as a query, such as for the antecedent formula in `log:implies`, statements including either explicit variables or blank nodes are treated as query patterns and are used to query the knowledge base to create a solution set, which is used either prove the formula correct, or create bindings passed to the consequent formula.

Blank nodes associated with rdf:List statements used as part of a built-in are made _non-distinguished_ existential variables, and patters containing these variables become optional. If they are not bound as part of the query, the implicitly are bound as the original blank nodes defined within the formula, which allows for both constant list arguments, list arguments that contain variables, or arguments which are variables expanding to lists.

## Dependencies
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.1, >= 3.1.4)
* [EBNF][EBNF gem] (~> 2.1)

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

### Additional vocabularies
* {RDF::N3::Rei}
* {RDF::N3::Crypto}
* {RDF::N3::Math}
* {RDF::N3::Time}

## Resources
* [RDF.rb][RDF.rb]
* [Distiller](http://rdf.greggkellogg.net/distiller)
* [Documentation](https://rubydoc.info/github/ruby-rdf/rdf-n3/)
* [History](file:file.History.html)
* [Notation-3][N3]
* [Team Submission][]
* [N3 Primer](https://www.w3.org/2000/10/swap/Primer.html)
* [N3 Reification](https://www.w3.org/DesignIssues/Reify.html)
* [Turtle][]
* [W3C SWAP Test suite](https://w3c.github.io/N3/tests/)
* [W3C Turtle Test suite](https://w3c.github.io/rdf-tests/turtle/)
* [N-Triples][]

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

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
[EBNF gem]:     https://ruby-rdf.github.com/ebnf
[RDF::Turtle]:  https://ruby-rdf.github.com/rdf-turtle/
[Design Issues]: https://www.w3.org/DesignIssues/Notation3.html "Notation-3 Design Issues"
[Team Submission]: https://www.w3.org/TeamSubmission/n3/
[Turtle]:       https://www.w3.org/TR/turtle/
[N-Triples]:    https://www.w3.org/TR/n-triples/
[YARD]:         https://yardoc.org/
[YARD-GS]:      https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:          https://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[SPARQL S-Expressions]: https://jena.apache.org/documentation/notes/sse.html
[W3C N3 Community Group]: https://www.w3.org/community/n3-dev/
[N3]:           https://w3c.github.io/N3/spec/
[PEG]:          https://en.wikipedia.org/wiki/Parsing_expression_grammar