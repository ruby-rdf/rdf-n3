# coding: utf-8
require_relative 'spec_helper'
require 'rdf/spec/writer'
require 'rdf/vocab'
require 'rdf/trig'

describe RDF::N3::Writer do
  let(:logger) {RDF::Spec.logger}
  before {logger.level = Logger::INFO if ENV['CI']}

  #after(:each) do |example|
  #  puts logger.to_s if
  #    example.exception &&
  #    !example.exception.is_a?(RSpec::Expectations::ExpectationNotMetError)
  #end

  it_behaves_like 'an RDF::Writer' do
    let(:writer) {RDF::N3::Writer.new(StringIO.new)}
  end

  describe ".for" do
    [
      :n3,
      'etc/doap.n3',
      {file_name:      'etc/doap.n3'},
      {file_extension: 'n3'},
      {content_type:   'text/n3'},
      {content_type:   'text/rdf+n3'},
      {content_type:   'application/rdf+n3'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Writer.for(arg)).to eq RDF::N3::Writer
      end
    end
  end

  describe "simple tests" do
    {
      "full URIs without base" => {
        input: %(<http://a/b> <http://a/c> <http://a/d> .),
        regexp: [%r(^<http://a/b> <http://a/c> <http://a/d> \.$)],
      },
      "relative URIs with base" => {
        input: %(<http://a/b> <http://a/c> <http://a/d> .),
        regexp: [ %r(^@base <http://a/> \.$), %r(^<b> <c> <d> \.$)],
        base_uri: "http://a/"
      },
      "pname URIs with prefix" => {
        input: %(<http://example.com/b> <http://example.com/c> <http://example.com/d> .),
        regexp: [
          %r(^@prefix ex: <http://example.com/> \.$),
          %r(^ex:b ex:c ex:d \.$)
        ],
        prefixes: {ex: "http://example.com/"}
      },
      "pname URIs with empty prefix" => {
        input: %(<http://example.com/b> <http://example.com/c> <http://example.com/d> .),
        regexp:  [
          %r(^@prefix : <http://example.com/> \.$),
          %r(^:b :c :d \.$)
        ],
        prefixes: {"" => "http://example.com/"}
      },
      # see example-files/arnau-registered-vocab.rb
      "pname URIs with empty suffix" => {
        input: %(<http://xmlns.com/foaf/0.1/> <http://xmlns.com/foaf/0.1/> <http://xmlns.com/foaf/0.1/> .),
        regexp:  [
          %r(^@prefix foaf: <http://xmlns.com/foaf/0.1/> \.$),
          %r(^foaf: foaf: foaf: \.$)
        ],
        prefixes: { "foaf" => "http://xmlns.com/foaf/0.1/"}
      },
      "order properties" => {
        input: %(
          @prefix ex: <http://example.com/> .
          @prefix dc: <http://purl.org/dc/elements/1.1/> .
          @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
          ex:b ex:c ex:d .
          ex:b dc:title "title" .
          ex:b a ex:class .
          ex:b rdfs:label "label" .
        ),
        regexp: [
          %r(^ex:b a ex:class;$),
          %r(ex:class;\s+rdfs:label "label")m,
          %r("label";\s+ex:c ex:d)m,
          %r(ex:d;\s+dc:title "title" \.$)m
        ],
      },
      "object list" => {
        input: %(@prefix ex: <http://example.com/> . ex:b ex:c ex:d, ex:e .),
        regexp: [
          %r(^@prefix ex: <http://example.com/> \.$),
          %r(^ex:b ex:c ex:[de],\s+ex:[de] \.$)m,
        ],
      },
      "property list" => {
        input: %(@prefix ex: <http://example.com/> . ex:b ex:c ex:d; ex:e ex:f .),
        regexp: [
          %r(^@prefix ex: <http://example.com/> \.$),
          %r(^ex:b ex:c ex:d;$),
          %r(^\s+ex:e ex:f \.$)
        ],
      },
      "bare anon" => {
        input: %(@prefix ex: <http://example.com/> . [ex:a ex:b] .),
        regexp: [%r(^\s*\[ex:a ex:b\] \.$)],
      },
      "anon as subject" => {
        input: %(@prefix ex: <http://example.com/> . [ex:a ex:b] ex:c ex:d .),
        regexp: [
          %r(^\s*\[\s*ex:a ex:b;$)m,
          %r(^\s+ex:c ex:d\s*\] \.$)m
        ],
      },
      "anon as object" => {
        input: %(@prefix ex: <http://example.com/> . ex:a ex:b [ex:c ex:d] .),
        regexp: [%r(^ex:a ex:b \[ex:c ex:d\] \.$)],
      },
      "standard prefixes" => {
        input: %(
          <a> a <http://xmlns.com/foaf/0.1/Person>;
            <http://purl.org/dc/terms/title> "Person" .
        ),
        regexp: [
          %r(^@prefix foaf: <http://xmlns.com/foaf/0.1/> \.$),
          %r(^@prefix dc: <http://purl.org/dc/terms/> \.$),
          %r(^<a> a foaf:Person;$),
          %r(dc:title "Person" \.$),
        ],
        standard_prefixes: true, prefixes: {}
      },
      "should not use pname with illegal local part" => {
        input: %(
          @prefix db: <http://dbpedia.org/resource/> .
          @prefix dbo: <http://dbpedia.org/ontology/> .
          db:Michael_Jackson dbo:artistOf <http://dbpedia.org/resource/(I_Can%27t_Make_It)_Another_Day> .
        ),
        regexp: [
          %r(^@prefix db: <http://dbpedia.org/resource/> \.$),
          %r(^db:Michael_Jackson dbo:artistOf <http://dbpedia.org/resource/\(I_Can%27t_Make_It\)_Another_Day> \.$)
        ],
        prefixes: {
          "db" => RDF::URI("http://dbpedia.org/resource/"),
          "dbo" => RDF::URI("http://dbpedia.org/ontology/")}
      }
    }.each do |name, params|
      it name do
        serialize(params[:input], params[:regexp], **params)
      end
    end
  end

  describe "collections" do
    {
      "bare list": {
        input: %(@prefix ex: <http://example.com/> . (ex:a ex:b) .),
        regexp: [%r(^\(\s*ex:a ex:b\s*\) \.$)],
        list_terms: true
      },
      "literal list": {
        input: %(@prefix ex: <http://example.com/> . ex:a ex:b ( "apple" "banana" ) .),
        regexp: [%r(^ex:a ex:b \(\s*"apple" "banana"\s*\) \.$)],
        list_terms: true
      },
      "empty list": {
        input: %(@prefix ex: <http://example.com/> . ex:a ex:b () .),
        regexp: [%r(^ex:a ex:b \(\s*\) \.$)],
        prefixes: { "" => RDF::Vocab::FOAF},
        list_terms: true
      },
      "should generate empty list(2)" => {
        input: %(@prefix : <http://xmlns.com/foaf/0.1/> . :emptyList = () .),
        regexp: [%r(^:emptyList (<.*sameAs>|owl:sameAs|=) \(\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"},
        list_terms: true
      },
      "empty list as subject": {
        input: %(@prefix ex: <http://example.com/> . () ex:a ex:b .),
        regexp: [%r(^\(\s*\) ex:a ex:b \.$)],
        list_terms: true
      },
      "list as subject": {
        input: %(@prefix ex: <http://example.com/> . (ex:a) ex:b ex:c .),
        regexp: [%r(^\(\s*ex:a\s*\) ex:b ex:c \.$)],
        list_terms: true
      },
      "list of empties": {
        input: %(@prefix ex: <http://example.com/> . [ex:listOf2Empties (() ())] .),
        regexp: [%r(\[\s*ex:listOf2Empties \(\s*\(\s*\) \(\s*\)\s*\)\s*\] \.$)],
        list_terms: true
      },
      "list anon": {
        input: %(@prefix ex: <http://example.com/> . [ex:twoAnons ([a ex:mother] [a ex:father])] .),
        regexp: [%r(\[\s*ex:twoAnons \(\s*\[\s*a ex:mother\s*\] \[\s*a ex:father\s*\]\)\] \.$)],
        list_terms: true
      },
      "list subjects": {
        input: %(@prefix ex: <http://example.com/> . (ex:a ex:b) . ex:a a ex:Thing . ex:b a ex:Thing .),
        regexp: [
          %r(\(ex:a ex:b\) \.),
          %r(ex:a a ex:Thing \.),
          %r(ex:b a ex:Thing \.),
        ],
        list_terms: true
      },
      "embedded list": {
        input: %{((:q)) a :Thing .},
        regexp: [
          %r{\(\(:q\)\) a :Thing \.}
        ],
        list_terms: true
      },
      "owl:unionOf list": {
        input: %(
          @prefix ex: <http://example.com/> .
          @prefix owl: <http://www.w3.org/2002/07/owl#> .
          @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
          ex:a rdfs:domain [
            a owl:Class;
            owl:unionOf [
              a owl:Class;
              rdf:first ex:b;
              rdf:rest [
                a owl:Class;
                rdf:first ex:c;
                rdf:rest rdf:nil
              ]
            ]
          ] .
        ),
        regexp: [
          %r(ex:a rdfs:domain \[\s*a owl:Class;\s+owl:unionOf\s+\(\s*ex:b\s+ex:c\s*\)\s*\]\s*\.$)m,
          %r(@prefix ex: <http://example.com/> \.),
          %r(@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> \.),
        ]
      },
      "list with first subject a URI": {
        input: %(
          <http://example.com> <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .
          <http://example.com> <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:g47006741228480 .
          _:g47006741228480 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "2"^^<http://www.w3.org/2001/XMLSchema#integer> .
          _:g47006741228480 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:g47006737917560 .
          _:g47006737917560 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "3"^^<http://www.w3.org/2001/XMLSchema#integer> .
          _:g47006737917560 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
        ),
        regexp: [
          %r(@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> \.),
          %r(<http://example.com> rdf:first 1;),
          %r(rdf:rest \(\s*2 3\s*\) \.),
        ],
        standard_prefixes: true
      },
      "list pattern without rdf:nil": {
        input: %(
          <http://example.com> <http://example.com/property> _:a .
          _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "a" .
          _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:b .
          _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "b" .
          _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:c .
          _:c <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "c" .
        ),
        regexp: [%r(<http://example.com> <http://example.com/property> \[),
          %r(rdf:first "a";),
          %r(rdf:rest \[),
          %r(rdf:first "b";),
          %r(rdf:rest \[\s*rdf:first "c"\s*\]),
        ],
        standard_prefixes: true
      },
      #"list pattern with extra properties": {
      #  input: %(
      #    <http://example.com> <http://example.com/property> _:a .
      #    _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "a" .
      #    _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:b .
      #    _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "b" .
      #    _:a <http://example.com/other-property> "This list node has also properties other than rdf:first and rdf:rest" .
      #    _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:c .
      #    _:c <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "c" .
      #    _:c <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
      #  ),
      #  regexp: [%r(<http://example.com> <http://example.com/property> \[),
      #    %r(<http://example.com/other-property> "This list node has also properties other than rdf:first and rdf:rest";),
      #    %r(rdf:first "a";),
      #    %r(rdf:rest \(\s*"b" "c"\s*\)),
      #  ],
      #  standard_prefixes: true
      #},
      "list with empty list": {
        input: %(
          <http://example.com/a> <http://example.com/property> _:l1 .
          _:l1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          _:l1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
        ),
        regexp: [
          %r(<http://example.com/a> <http://example.com/property> \(\s*\(\)\) .)
        ],
        standard_prefixes: true
      },
      "list with multiple lists": {
        input: %(
          <http://example.com/a> <http://example.com/property> _:l1 .
          _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "a" .
          _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "b" .
          _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          _:l1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> _:a .
          _:l1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:l2 .
          _:l2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> _:b .
          _:l2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
        ),
        regexp: [
          %r(<http://example.com/a> <http://example.com/property> \(\s*\(\s*"a"\) \(\s*"b"\)\) .)
        ],
        standard_prefixes: true
      },
      "list with formula": {
        input: %(
          @prefix log:  <http://www.w3.org/2000/10/swap/log#> .
          {
            ({:sky :color :blue} {:sky :color :green}) log:conjunction ?F
          } =>  {  ?F a :result} .
        ),
        regexp: [
          %r[{\s+\(\s*{\s*:sky :color :blue \.\s+}\s+{]m,
          %r[{\s+:sky :color :green \.\s+}\s*\)]m,
          %r[}\)\s+log:conjunction\s+\?F\s+\.\s+} =>]m,
          %r[=>\s+{\s+\?F a :result \.\s*}]m
        ]
      },
    }.each do |name, params|
      it name do
        serialize(params[:input], params[:regexp], **params)
      end
    end
  end

  describe "literals" do
    describe "xsd:anyURI" do
      it "uses xsd namespace for datatype" do
        ttl = %q(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> "http://foo/"^^xsd:anyURI .)
        serialize(ttl, [
          %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
          %r("http://foo/"\^\^xsd:anyURI \.),
        ])
      end
    end
    
    describe "xsd:boolean" do
      [
        [%q("true"^^xsd:boolean), /true ./],
        [%q("TrUe"^^xsd:boolean), /true ./],
        [%q("1"^^xsd:boolean), /true ./],
        [%q(true), /true ./],
        [%q("false"^^xsd:boolean), /false ./],
        [%q("FaLsE"^^xsd:boolean), /false ./],
        [%q("0"^^xsd:boolean), /false ./],
        [%q(false), /false ./],
      ].each do |(l,r)|
        it "uses token for #{l.inspect}" do
          ttl = %(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> #{l} .)
          serialize(ttl, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
        end
      end

      [
        [true, "true"],
        [false, "false"],
        [1, "true"],
        [0, "false"],
        ["true", "true"],
        ["false", "false"],
        ["1", "true"],
        ["0", "false"],
        ["string", %{"string"^^<http://www.w3.org/2001/XMLSchema#boolean>}],
      ].each do |(l,r)|
        it "serializes #{l.inspect} to #{r.inspect}" do
          expect(subject.format_literal(RDF::Literal::Boolean.new(l))).to eql r
        end
      end
    end
    
    describe "xsd:integer" do
      [
        [%q("1"^^xsd:integer), /1 ./],
        [%q(1), /1 ./],
        [%q("0"^^xsd:integer), /0 ./],
        [%q(0), /0 ./],
        [%q("10"^^xsd:integer), /10 ./],
        [%q(10), /10 ./],
      ].each do |(l,r)|
        it "uses token for #{l.inspect}" do
          ttl = %(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> #{l} .)
          serialize(ttl, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
        end
      end

      [
        [0, "0"],
        [10, "10"],
        [-1, "-1"],
        ["0", "0"],
        ["true", %{"true"^^<http://www.w3.org/2001/XMLSchema#integer>}],
        ["false", %{"false"^^<http://www.w3.org/2001/XMLSchema#integer>}],
        ["string", %{"string"^^<http://www.w3.org/2001/XMLSchema#integer>}],
      ].each do |(l,r)|
        it "serializes #{l.inspect} to #{r.inspect}" do
          expect(subject.format_literal(RDF::Literal::Integer.new(l))).to eql r
        end
      end
    end

    describe "xsd:int" do
      [
        [%q("1"^^xsd:int), /"1"\^\^xsd:int ./],
        [%q("0"^^xsd:int), /"0"\^\^xsd:int ./],
        [%q("10"^^xsd:int), /"10"\^\^xsd:int ./],
      ].each do |(l,r)|
        it "uses token for #{l.inspect}" do
          ttl = %(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> #{l} .)
          serialize(ttl, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
        end
      end
    end

    describe "xsd:decimal" do
      [
        [%q("1.0"^^xsd:decimal), /1.0 ./],
        [%q(1.0), /1.0 ./],
        [%q("0.1"^^xsd:decimal), /0.1 ./],
        [%q(0.1), /0.1 ./],
        [%q("10.02"^^xsd:decimal), /10.02 ./],
        [%q(10.02), /10.02 ./],
      ].each do |(l,r)|
        it "uses token for #{l.inspect}" do
          ttl = %(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> #{l} .)
          serialize(ttl, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
        end
      end

      [
        [0, "0.0"],
        [10, "10.0"],
        [-1, "-1.0"],
        ["0", "0.0"],
        ["10", "10.0"],
        ["-1", "-1.0"],
        ["1.0", "1.0"],
        ["0.1", "0.1"],
        ["10.01", "10.01"],
        ["true", %{"true"^^<http://www.w3.org/2001/XMLSchema#decimal>}],
        ["false", %{"false"^^<http://www.w3.org/2001/XMLSchema#decimal>}],
        ["string", %{"string"^^<http://www.w3.org/2001/XMLSchema#decimal>}],
      ].each do |(l,r)|
        it "serializes #{l.inspect} to #{r.inspect}" do
          expect(subject.format_literal(RDF::Literal::Decimal.new(l))).to eql r
        end
      end
    end
    
    describe "xsd:double" do
      [
        [%q("1.0e1"^^xsd:double), /1.0e1 ./],
        [%q(1.0e1), /1.0e1 ./],
        [%q("0.1e1"^^xsd:double), /1.0e0 ./],
        [%q(0.1e1), /1.0e0 ./],
        [%q("10.02e1"^^xsd:double), /1.002e2 ./],
        [%q(10.02e1), /1.002e2 ./],
        [%q("14"^^xsd:double), /1.4e1 ./],
      ].each do |(l,r)|
        it "uses token for #{l.inspect}" do
          ttl = %(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . <http://a> <http:/b> #{l} .)
          serialize(ttl, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
        end
      end

      [
        [0, "0.0e0"],
        [10, "1.0e1"],
        [-1, "-1.0e0"],
        ["0", "0.0e0"],
        ["10", "1.0e1"],
        ["-1", "-1.0e0"],
        ["1.0", "1.0e0"],
        ["0.1", "1.0e-1"],
        ["10.01", "1.001e1"],
        ["true", %{"true"^^<http://www.w3.org/2001/XMLSchema#double>}],
        ["false", %{"false"^^<http://www.w3.org/2001/XMLSchema#double>}],
        ["string", %{"string"^^<http://www.w3.org/2001/XMLSchema#double>}],
      ].each do |(l,r)|
        it "serializes #{l.inspect} to #{r.inspect}" do
          expect(subject.format_literal(RDF::Literal::Double.new(l))).to eql r
        end
      end
    end
  end

  describe "formulae" do
    {
      "empty subject" => {
        input: %({} <b> <c> .),
        regexp: [
          %r({} <b> <c> \.)
        ]
      },
      "empty object" => {
        input: %(<a> <b> {} .),
        regexp: [
          %r(<a> <b> {} \.)
        ]
      },
      "as subject with constant content" => {
        input: %({<x> <y> <z>} <b> <c> .),
        regexp: [
          %r({\s+<x> <y> <z> \.\s+} <b> <c> \.)m
        ]
      },
      "as object with constant content" => {
        input: %(<a> <b> {<x> <y> <z>} .),
        regexp: [
          %r(<a> <b> {\s+<x> <y> <z> \.\s+} \.)m
        ]
      },
      "implies" => {
        input: %({ _:x :is _:x } => {_:x :is _:x } .),
        regexp: [
          %r({\s+_:b0 :is _:b0 \.\s+} => {\s+_:b1 :is _:b1 \.\s+} \.)m
        ]
      },
      "formula simple" => {
        input: %(<> :about { :c :d :e }.),
        regexp: [
          %r(<> :about {\s+:c :d :e \.\s+} \.)
        ]
      },
      "nested" => {
        input: %(
          @prefix doc:  <http://www.w3.org/2000/10/swap/pim/doc#> .
          @prefix ex:   <http://www.example.net/2000/10/whatever#> .
          @prefix contact:  <http://www.w3.org/2000/10/swap/pim/contact#> .
          []
            doc:creator [contact:email <mailto:fred@example.com> ];
            ex:says  {
              [] doc:title "Huckleberry Finn";
                doc:creator [contact:knownAs "Mark Twain"]
            }.
        ),
        regexp: [
          %r(\[\s+ex:says {\s+\[)m,
          %r(doc:creator \[contact:knownAs "Mark Twain"\];),
          %r(doc:title "Huckleberry Finn"),
          %r(\] \.\s+};)m,
          %r(doc:creator \[contact:email <mailto:fred@example.com>)
        ]
      },
      "named with URI" => {
        input: %q(
          <a> <b> <c> .
          <C> {<A> <b> <c> .}
        ),
        regexp: [
          %r(<a> <b> <c> \.),
          %r(<C> = {),
          %r(<A> <b> <c> \.),
          %r(} \.),
        ],
        input_format: :trig
      },
      "named with BNode" => {
        input: %q(
          <a> <b> <c> .
          _:C {<A> <b> <c> .}
        ),
        regexp: [
          %r(<a> <b> <c> \.),
          %r(_:C = {),
          %r(<A> <b> <c> \.),
          %r(} \.),
        ],
        input_format: :trig
      },
      "implication" => {
        input: %q(
          @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          ("17"^^xsd:integer) a <#TestCase> .
          { ( ?x ) a :TestCase}  => { ?x a :RESULT } .
        ),
        regexp: [
          %r{\(17\) a :TestCase \.},
          %r{\(?x\) a :TestCase \.},
          %r{\?x a :RESULT \.},
        ]
      },
    }.each do |name, params|
      it name do
        serialize(params[:input], params[:regexp], **params)
      end
    end
  end

  describe "variables" do
    {
      "?o": {
        input: %(:s :p ?o .),
        regexp: [
          %r(:s :p \?o \.),
        ]
      },
    }.each do |name, params|
      it name do
        serialize(params[:input], params[:regexp], **params)
      end
    end
  end

  describe "results" do
    {
      "r1": {
        input: %(
          ( "one"  "two" ) a :whatever.
          "one" a :SUCCESS.
          "two" a :SUCCESS.
        ),
        regexp: [
          %r(\(\s*"one"\s+"two"\s*\) a :whatever\s*\.),
          %r("one" a :SUCCESS \.),
          %r("two" a :SUCCESS \.),
        ]
      },
    }.each do |name, params|
      it name do
        serialize(params[:input], params[:regexp], list_terms: true, **params)
      end
    end
  end

  # W3C TriG Test suite
  describe "w3c n3 parser tests" do
    require_relative 'suite_helper'

    Fixtures::SuiteTest::Manifest.open("https://w3c.github.io/N3/tests/N3Tests/manifest-parser.ttl") do |m|
      describe m.comment do
        m.entries.each do |t|
          next if t.negative_test? || t.approval == 'rdft:Rejected'
          specify "#{t.rel}: #{t.name}: #{t.comment} (action)" do
            case t.rel
            when *%w(cwm_syntax_path2.n3
                     cwm_includes_builtins.n3
                     cwm_list_unify5-ref.n3
                     cwm_other_lists-simple.n3
                     cwm_other_lists.n3   # empty list with extra properties
                     new_syntax_inverted_properties.n3
                     cwm_other_dec-div.n3 cwm_syntax_sep-term.n3
                     manifest-parser.ttl
                     )
              pending "Investigate"
            when *%w(cwm_syntax_boolean.n3)
              pending "Number syntax"
            when *%w(cwm_syntax_bad-preds-formula.n3
                     cwm_syntax_path2.n3)
              pending "Anonymous properties"
            when *%w(cwm_syntax_too-nested.n3 cwm_list_unify4.n3)
              skip("stack overflow")
            when *%w(manifest.ttl cwm_math_math-test.n3 cwm_other_daml-ex.n3
                     cwm_math_math-test.n3 cwm_syntax_this-quantifiers-ref.n3)
              skip("too long")
            end

            logger.info t.inspect
            logger.info "source: #{t.input}"
            repo = parse(t.input, base_uri: t.base, logger: false)
            logger.info("sxp: #{SXP::Generator.string(repo.to_sxp_bin)}")
            n3 = serialize(repo, [], base_uri: t.base, standard_prefixes: true, logger: logger)
            g2 = parse(n3, validate: true, base_uri: t.base, logger: logger)
            expect(g2.count).to produce(repo.count, logger)
            expect(g2.isomorphic?(repo)).to produce(true, logger)
          end

          next if t.syntax? || t.reason?
          specify "#{t.name}: #{t.comment} (result)" do
            case t.name
            when *%w(cwm_syntax_path2.n3 path2.n3)
              pending "Investigate"
            when *%w(numbers.n3)
              pending "Number syntax"
            when *%w(cwm_syntax_too-nested.n3)
              skip("stack overflow")
            end

            logger.info t.inspect
            logger.info "source: #{t.expected}"
            format = detect_format(t.expected)
            repo = parse(t.expected, base_uri: t.base, format: format, logger: false)
            n3 = serialize(repo, [], base_uri: t.base, standard_prefixes: true, logger: logger)
            g2 = parse(n3, validate: true, base_uri: t.base, logger: false)
            expect(g2.isomorphic?(repo)).to produce(true, logger)
          end
        end
      end
    end
  end unless ENV['CI']

  def parse(input, format: :n3, **options)
    repo = [].extend(RDF::Enumerable, RDF::Queryable)
    reader = RDF::Reader.for(format)
    reader.new(input, **options).each_statement {|st| repo << st}
    repo
  end

  # Serialize ntstr to a string and compare against regexps
  def serialize(ntstr, regexps = [], base_uri: nil, **options)
    prefixes = options[:prefixes] || {}
    g = ntstr.is_a?(RDF::Enumerable) ? ntstr : parse(ntstr, base_uri: base_uri, prefixes: prefixes, validate: false, logger: false, format: options.fetch(:input_format, :n3))
    result = RDF::N3::Writer.buffer(**options.merge(logger: logger, base_uri: base_uri, prefixes: prefixes)) do |writer|
      g.each_statement {|st| writer << st}
    end
    if $verbose
      require 'cgi'
      #puts CGI.escapeHTML(result)
    end
    
    logger.info "result: #{result}"
    regexps.each do |re|
      logger.info "match: #{re.inspect}"
      expect(result).to match_re(re, about: base_uri, logger: logger, input: ntstr), logger.to_s
    end
    
    result
  end
end