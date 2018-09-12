# coding: utf-8
$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/writer'

describe RDF::N3::Writer do
  let(:logger) {RDF::Spec.logger}

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
    it "should use full URIs without base" do
      input = %(<http://a/b> <http://a/c> <http://a/d> .)
      serialize(input, nil, [%r(^<http://a/b> <http://a/c> <http://a/d> \.$)])
    end

    it "should use relative URIs with base" do
      input = %(<http://a/b> <http://a/c> <http://a/d> .)
      serialize(input, "http://a/",
       [ %r(^@base <http://a/> \.$),
        %r(^<b> <c> <d> \.$)]
      )
    end

    it "should use qname URIs with prefix" do
      input = %(<http://xmlns.com/foaf/0.1/b> <http://xmlns.com/foaf/0.1/c> <http://xmlns.com/foaf/0.1/d> .)
      serialize(input, nil,
        [%r(^@prefix foaf: <http://xmlns.com/foaf/0.1/> \.$),
        %r(^foaf:b foaf:c foaf:d \.$)],
        prefixes: { foaf: "http://xmlns.com/foaf/0.1/"}
      )
    end

    it "should use qname URIs with empty prefix" do
      input = %(<http://xmlns.com/foaf/0.1/b> <http://xmlns.com/foaf/0.1/c> <http://xmlns.com/foaf/0.1/d> .)
      serialize(input, nil,
        [%r(^@prefix : <http://xmlns.com/foaf/0.1/> \.$),
        %r(^:b :c :d \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    # see example-files/arnau-registered-vocab.rb
    it "should use qname URIs with empty suffix" do
      input = %(<http://xmlns.com/foaf/0.1/> <http://xmlns.com/foaf/0.1/> <http://xmlns.com/foaf/0.1/> .)
      serialize(input, nil,
        [%r(^@prefix foaf: <http://xmlns.com/foaf/0.1/> \.$),
        %r(^foaf: foaf: foaf: \.$)],
        prefixes: { "foaf" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should not use qname with illegal local part" do
      input = %(
        @prefix db: <http://dbpedia.org/resource/> .
        @prefix dbo: <http://dbpedia.org/ontology/> .
        db:Michael_Jackson dbo:artistOf <http://dbpedia.org/resource/%28I_Can%27t_Make_It%29_Another_Day> .
      )

      serialize(input, nil,
        [%r(^@prefix db: <http://dbpedia.org/resource/> \.$),
        %r(^db:Michael_Jackson dbo:artistOf <http://dbpedia.org/resource/%28I_Can%27t_Make_It%29_Another_Day> \.$)],
        prefixes: {
          "db" => RDF::URI("http://dbpedia.org/resource/"),
          "dbo" => RDF::URI("http://dbpedia.org/ontology/")}
      )
    end

    it "should order properties" do
      input = %(
        @prefix : <http://xmlns.com/foaf/0.1/> .
        @prefix dc: <http://purl.org/dc/elements/1.1/> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        :b :c :d .
        :b dc:title "title" .
        :b a :class .
        :b rdfs:label "label" .
      )
      serialize(input, nil,
        [
          %r(^:b a :class;$),
          %r(:class;\s+rdfs:label "label")m,
          %r("label";\s+dc:title "title")m,
          %r("title";\s+:c :d \.$)m
        ],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/", dc: "http://purl.org/dc/elements/1.1/", rdfs: RDF::RDFS}
      )
    end
    
    it "should generate object list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :b :c :d, :e .)
      serialize(input, nil,
        [%r(^@prefix : <http://xmlns.com/foaf/0.1/> \.$),
        %r(^:b :c :[de],\s+:[de] \.$)m],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate property list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :b :c :d; :e :f .)
      serialize(input, nil,
        [%r(^@prefix : <http://xmlns.com/foaf/0.1/> \.$),
        %r(^:b :[ce] :[df];\s+:[ce] :[df] \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
  end
  
  describe "anons" do
    it "should generate bare anon" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . [:a :b] .)
      serialize(input, nil,
        [%r(^\s*\[ :a :b\] \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate anon as subject" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . [:a :b] :c :d .)
      serialize(input, nil,
        [%r(^\s*\[ :a :b;$),
        %r(^\s+:c :d\] \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate anon as object" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :a :b [:c :d] .)
      serialize(input, nil,
        [%r(^\s*\:a :b \[ :c :d\] \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
  end

  describe "BNodes" do
    let(:input) {%(@prefix : <http://xmlns.com/foaf/0.1/> . _:a :b _:a .)}
    it "reuses BNode labels by default" do
      serialize(input, nil,
        [%r(^\s*_:a :b _:a \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    it "uses generated BNodes with :unique_bnodes" do
      serialize(input, nil,
        [%r(^\s*_:g\w+ :b _:g\w+ \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"},
        unique_bnodes: true
      )
    end
  end

  describe "lists" do
    it "should generate bare list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . (:a :b) .)
      serialize(input, nil,
        [%r(^\(:a :b\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end

    it "should generate literal list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :a :b ( "apple" "banana" ) .)
      serialize(input, nil,
        [%r(^:a :b \("apple" "banana"\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate empty list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :a :b () .)
      serialize(input, nil,
        [%r(^:a :b \(\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate empty list(2)" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :emptyList = () .)
      serialize(input, nil,
        [%r(^:emptyList (<.*sameAs>|owl:sameAs) \(\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate empty list as subject" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . () :a :b .)
      serialize(input, nil,
        [%r(^\(\) :a :b \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate list as subject" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . (:a) :b :c .)
      serialize(input, nil,
        [%r(^\(:a\) :b :c \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end

    it "should generate list of empties" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :listOf2Empties = (() ()) .)
      serialize(input, nil,
        [%r(^:listOf2Empties (<.*sameAs>|owl:sameAs) \(\(\) \(\)\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate list anon" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :twoAnons = ([a :mother] [a :father]) .)
      serialize(input, nil,
        [%r(^:twoAnons (<.*sameAs>|owl:sameAs) \(\[\s*a :(mother|father)\] \[\s*a :(mother|father)\]\) \.$)],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/"}
      )
    end
    
    it "should generate owl:unionOf list" do
      input = %(
        @prefix : <http://xmlns.com/foaf/0.1/> .
        @prefix owl: <http://www.w3.org/2002/07/owl#> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        :a rdfs:domain [
          a owl:Class;
          owl:unionOf [
            a owl:Class;
            rdf:first :b;
            rdf:rest [
              a owl:Class;
              rdf:first :c;
              rdf:rest rdf:nil
            ]
          ]
        ] .
      )
      #$verbose = true
      serialize(input, nil,
        [
          %r(:a rdfs:domain \[\s*a owl:Class;\s+owl:unionOf\s+\(:b\s+:c\)\]\s*\.$)m,
          %r(@prefix : <http://xmlns.com/foaf/0.1/> \.),
          %r(@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> \.),
        ],
        prefixes: { "" => "http://xmlns.com/foaf/0.1/", dfs: RDF::RDFS, owl: RDF::OWL, rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#"}
      )
      #$verbose = false
    end

    it "should generate list with first subject a URI" do
      input = %(
      <http://example.com> <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .
      <http://example.com> <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:g47006741228480 .
      _:g47006741228480 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "2"^^<http://www.w3.org/2001/XMLSchema#integer> .
      _:g47006741228480 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:g47006737917560 .
      _:g47006737917560 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "3"^^<http://www.w3.org/2001/XMLSchema#integer> .
      _:g47006737917560 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
      )
      #$verbose = true
      serialize(input, nil,
        [
          %r(@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> \.),
          %r(<http://example.com> rdf:first 1;),
          %r(rdf:rest \(2 3\) \.),
        ],
        standard_prefixes: true
      )
      #$verbose = false
    end
  end

  describe "literals" do
    describe "plain" do
      it "encodes embedded \"\"\"" do
        n3 = %(:a :b """testing string parsing in N3.
  """ .)
        serialize(n3, nil, [/testing string parsing in N3.\n/])
      end

      it "encodes embedded \"" do
        n3 = %(:a :b """string with " escaped quote marks""" .)
        serialize(n3, nil, [/string with \\" escaped quote mark/])
      end

      it "encodes embedded \\" do
        n3 = %(:a :b """string with \\\\ escaped quote marks""" .)
        serialize(n3, nil, [/string with \\\\ escaped quote mark/])
      end

      it "encodes embedded \\ multi-line" do
        n3 = %(:a :b """string with \\\\ escaped quote marks
  """ .)
        serialize(n3, nil, [/string with \\\\ escaped quote mark/])
      end
    end
    
    describe "with language" do
      it "specifies language for literal with language" do
        ttl = %q(:a :b "string"@en .)
        serialize(ttl, nil, [%r("string"@en)])
      end
    end
    
    describe "xsd:anyURI" do
      it "uses xsd namespace for datatype" do
        ttl = %q(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b "http://foo/"^^xsd:anyURI .)
        serialize(ttl, nil, [
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
          ttl = %(@prefix : <http://example> . @prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b #{l} .)
          serialize(ttl, nil, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
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
          ttl = %(@prefix : <http://example> . @prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b #{l} .)
          serialize(ttl, nil, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
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
          ttl = %(@prefix : <http://example> . @prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b #{l} .)
          serialize(ttl, nil, [
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
          ttl = %(@prefix : <http://example> . @prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b #{l} .)
          serialize(ttl, nil, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
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
      ].each do |(l,r)|
        it "uses token for #{l.inspect}" do
          ttl = %(@prefix : <http://example> . @prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b #{l} .)
          serialize(ttl, nil, [
            %r(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> \.),
            r,
          ], canonicalize: true)
        end
      end
    end
  end

  def parse(input, options = {})
    graph = RDF::Graph.new
    RDF::N3::Reader.new(input, options).each do |statement|
      graph << statement
    end
    graph
  end

  # Serialize ntstr to a string and compare against regexps
  def serialize(ntstr, base = nil, regexps = [], options = {})
    prefixes = options[:prefixes] || {}
    g = ntstr.is_a?(RDF::Enumerable) ? ntstr : parse(ntstr, base_uri: base, prefixes: prefixes, validate: false, logger: [])
    result = RDF::N3::Writer.buffer(options.merge(logger: logger, base_uri: base, prefixes: prefixes)) do |writer|
      writer << g
    end
    if $verbose
      require 'cgi'
      #puts CGI.escapeHTML(result)
    end
    
    logger.info "result: #{result}"
    regexps.each do |re|
      logger.info "match: #{re.inspect}"
      expect(result).to match_re(re, about: base, logger: logger, input: ntstr), logger.to_s
    end
    
    result
  end
end