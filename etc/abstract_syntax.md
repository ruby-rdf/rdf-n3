# Notation-3 Abstract Syntax

The [Notation-3][] Abstract Syntax generalizes the the [RDF Abstract Syntax](https://www.w3.org/TR/rdf11-concepts/) defined in [[RDF11-Concepts][]] further generalizing the concepts of [generalized RDF triple](https://www.w3.org/TR/rdf11-concepts/#dfn-generalized-rdf-triple) and [generalized RDF graph](https://www.w3.org/TR/rdf11-concepts/#dfn-generalized-rdf-graph).

An [N3 triple](https://w3c.github.io/N3/spec/#N3-triple) is composed of three [N3 triple elements](https://w3c.github.io/N3/spec/#dfn-triple-elements), which each element can be an [IRI](https://www.w3.org/TR/rdf11-concepts/#dfn-iri), [blank node](https://www.w3.org/TR/rdf11-concepts/#dfn-blank-node), [literal](https://www.w3.org/TR/rdf11-concepts/#dfn-literal), [list](https://w3c.github.io/N3/spec/#lists), [N3 graph](#n3-graph), or universal variable.

An <a id="n3-graph">N3 graph</a> abstracts a [generalized RDF graph](https://www.w3.org/TR/rdf11-concepts/#dfn-generalized-rdf-graph) is then a set of zero or more [N3 triples](https://w3c.github.io/N3/spec/#N3-triple) also having zero or more bound [universal variables](https://w3c.github.io/N3/spec/#dfn-universals).

When appearing as the subject, predicate, or object of an [N3 triple](https://w3c.github.io/N3/spec/#N3-triple), an [N3 graph](#n3-graph) may also be quantified, unless given a separate interpretation by the semantics defined for the associated predicate (e.g., when it is a builtin).

Note that in Notation-3, a [list](https://w3c.github.io/N3/spec/#lists) is a first-class resource, which may be quantified when appearing with a [quantified N3 formula](https://w3c.github.io/N3/spec/#quantified-formula). The notion of [RDF Collection](https://www.w3.org/TR/rdf11-mt/#rdf-collections) from [[RDF 1.1 Semantics](https://www.w3.org/TR/rdf11-mt/)] may be considered as a reification of an [N3 list](https://w3c.github.io/N3/spec/#lists).

## Relationship to Datasets

The description of the Abstract Syntax is based on the notion of resources, triples and graphs, where a graph may be a triple component, thus creating a recursive graph. This is similar to the notion of an [RDF dataset](https://www.w3.org/TR/rdf11-concepts/#dfn-rdf-dataset) where a blank node becomes a stand-in for the graph when used within a triple, and that same blank node names a named graph containing the triples from the referenced graph. The fact that both blank nodes and N3 graphs are existentially quantized leads to similar semantics, although in RDF, datasets have no defined semantics.

## Notes

[Blank nodes](https://www.w3.org/TR/rdf11-concepts/#dfn-blank-node) in Notation-3 are unique across [N3 graphs](#n3-graph), unlike in other RDF syntaxes, however this is considered a concrete syntax-level concern, and does not affect the abstract syntax.

Similarly, both [Blank Nodes](https://www.w3.org/TR/rdf11-concepts/#dfn-blank-node) and [universal variables](https://w3c.github.io/N3/spec/#dfn-universals) act as quantifiers and are scoped to a particular [N3 graph](#n3-graph). This can also be considered a concrete syntax-level concern which can be addressed by appropriately renaming variables at the global scope.

An [N3 graph](#n3-graph) is often referred to as a [formula](https://w3c.github.io/N3/spec/#N3-formula) (plural, formulae), however, the concept of formula in N3 also includes [N3 triples](https://w3c.github.io/N3/spec/#N3-triple).

[Notation-3]:   https://w3c.github.io/N3/spec/
[RDF11-Concepts]: https://www.w3.org/TR/rdf11-concepts/