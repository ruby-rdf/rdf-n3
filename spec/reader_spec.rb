# coding: utf-8
require_relative 'spec_helper'
require 'rdf/spec/reader'
require 'rdf/trig'

describe "RDF::N3::Reader" do
  let!(:doap) {File.expand_path("../../etc/doap.n3", __FILE__)}
  let!(:doap_nt) {File.expand_path("../../etc/doap.nt", __FILE__)}
  let!(:doap_count) {File.open(doap_nt).each_line.to_a.length}
  let(:logger) {RDF::Spec.logger}

  after(:each) do |example|
    puts logger.to_s if
      example.exception &&
      !example.exception.is_a?(RSpec::Expectations::ExpectationNotMetError)
  end

  it_behaves_like 'an RDF::Reader' do
    let(:reader) {RDF::N3::Reader.new(reader_input, logger: logger)}
    let(:reader_input) {File.read(doap)}
    let(:reader_count) {doap_count}
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
        expect(RDF::Reader.for(arg)).to eq RDF::N3::Reader
      end
    end
  end

  context :interface do
    before(:each) do
      @sampledoc = <<-EOF;
        @prefix dc: <http://purl.org/dc/elements/1.1/>.
        @prefix po: <http://purl.org/ontology/po/>.
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
        _:broadcast
         a po:Broadcast;
         po:schedule_date """2008-06-24T12:00:00Z""";
         po:broadcast_of _:version;
         po:broadcast_on <http://www.bbc.co.uk/programmes/service/6music>;
        .
        _:version
         a po:Version;
        .
        <http://www.bbc.co.uk/programmes/b0072l93>
         dc:title """Nemone""";
         a po:Brand;
        .
        <http://www.bbc.co.uk/programmes/b00c735d>
         a po:Episode;
         po:episode <http://www.bbc.co.uk/programmes/b0072l93>;
         po:version _:version;
         po:long_synopsis """Actor and comedian Rhys Darby chats to Nemone.""";
         dc:title """Nemone""";
         po:synopsis """Actor and comedian Rhys Darby chats to Nemone.""";
        .
        <http://www.bbc.co.uk/programmes/service/6music>
         a po:Service;
         dc:title """BBC 6 Music""";
        .

        #_:abcd a po:Episode.
      EOF
    end

    it "should yield reader" do
      inner = double("inner")
      expect(inner).to receive(:called).with(RDF::N3::Reader)
      RDF::N3::Reader.new(@sampledoc) do |reader|
        inner.called(reader.class)
      end
    end

    it "should return reader" do
      expect(RDF::N3::Reader.new(@sampledoc)).to be_a(RDF::N3::Reader)
    end

    it "should yield statements" do
      inner = double("inner")
      expect(inner).to receive(:called).with(RDF::Statement).exactly(15)
      RDF::N3::Reader.new(@sampledoc, logger: logger).each_statement do |statement|
        inner.called(statement.class)
      end
    end

    it "should yield triples" do
      inner = double("inner")
      expect(inner).to receive(:called).exactly(15)
      RDF::N3::Reader.new(@sampledoc).each_triple do |subject, predicate, object|
        inner.called(subject.class, predicate.class, object.class)
      end
    end
  end

  describe "with simple ntriples" do
    context "simple triple" do
      before(:each) do
        n3_string = %(<http://example.org/> <http://xmlns.com/foaf/0.1/name> "Gregg Kellogg" .)
        @graph = parse(n3_string)
        @statement = @graph.statements.first
      end

      it "should have a single triple" do
        expect(@graph.size).to eq 1
      end

      it "should have subject" do
        expect(@statement.subject.to_s).to eq "http://example.org/"
      end
      it "should have predicate" do
        expect(@statement.predicate.to_s).to eq "http://xmlns.com/foaf/0.1/name"
      end
      it "should have object" do
        expect(@statement.object.to_s).to eq "Gregg Kellogg"
      end
    end

    # NTriple tests from http://www.w3.org/2000/10/rdf-tests/rdfcore/ntriples/test.nt
    describe "with blank lines" do
      {
        "comment"                   => "# comment lines",
        "comment after whitespace"  => "            # comment after whitespace",
        "empty line"                => "",
        "line with spaces"          => "      "
      }.each_pair do |name, statement|
        specify "test #{name}" do
          expect(parse(statement)).to be_empty
        end
      end
    end

    describe "with literal encodings" do
      {
        'Dürst' => ':a :b "D\u00FCrst" .',
        'simple literal' => ':a :b  "simple literal" .',
        'backslash:\\' => ':a :b  "backslash:\\\\" .',
        'dquote:"' => ':a :b  "dquote:\"" .',
        "newline:\n" => ':a :b  "newline:\n" .',
        "return\r" => ':a :b  "return\r" .',
        "tab:\t" => ':a :b  "tab:\t" .',
        "é" => ':a :b  "\u00E9" .',
        "€" => ':a :b  "\u20AC" .',
        "resumé" => ':a :resume  "resum\u00E9" .',
      }.each_pair do |contents, triple|
        specify "test #{triple}" do
          graph = parse(triple, base_uri: "http://a/b")
          statement = graph.statements.first
          expect(graph.size).to eq 1
          expect(statement.object.value).to eq contents
        end
      end

      {
        'Dürst' => '<a> <b> "Dürst" .',
        "é" => '<a> <b>  "é" .',
        "€" => '<a> <b>  "€" .',
        "resumé" => ':a :resume  "resumé" .',
      }.each_pair do |contents, triple|
        specify "test #{triple}" do
          graph = parse(triple, base_uri: "http://a/b", logger: false)
          statement = graph.statements.first
          expect(graph.size).to eq 1
          expect(statement.object.value).to eq contents
        end
      end

      it "should parse long literal with escape" do
        n3 = %(@prefix : <http://example.org/foo#> . :a :b """\\U00015678another""" .)
        statement = parse(n3).statements.first
        expect(statement.object.value).to eq "\u{15678}another"
      end

      it "should parse long literal single quote with escape" do
        n3 = %(@prefix : <http://example.org/foo#> . :a :b '''\\U00015678another''' .)
        statement = parse(n3).statements.first
        expect(statement.object.value).to eq "\u{15678}another"
      end

      context "string3 literals" do
        {
          "simple" => %q(foo),
          "muti-line" => %q(
              Foo
              <html:b xmlns:html="http://www.w3.org/1999/xhtml" html:a="b">
                bar
                <rdf:Thing xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                  <a:b xmlns:a="foo:"></a:b>
                  here
                  <a:c xmlns:a="foo:"></a:c>
                </rd
                f:Thing>
              </html:b>
              baz
              <html:i xmlns:html="http://www.w3.org/1999/xhtml">more</html:i>
            ),
          "trailing escaped double-quote" => %q( " ),
          "regression.n3" => %q(sameDan.n3 sameThing.n3 --think --apply=forgetDups.n3 --purge --n3="/" )
        }.each do |test, string|
          it "parses #{test}" do
            graph = parse(%(:a :b """#{string}""" .))
            expect(graph.size).to eq 1
            expect(graph.statements.first.object.value).to eq string
          end
        end
      end
    end

    it "should create named subject bnode" do
      graph = parse("_:anon <http://example.org/property> <http://example.org/resource2> .")
      expect(graph.size).to eq 1
      statement = graph.statements.first
      expect(statement.subject).to be_a(RDF::Node)
      expect(statement.subject.id).to match(/anon/)
      expect(statement.predicate.to_s).to eq "http://example.org/property"
      expect(statement.object.to_s).to eq "http://example.org/resource2"
    end

    it "should create named predicate bnode" do
      graph = parse("<http://example.org/resource2> _:anon <http://example.org/object> .")
      expect(graph.size).to eq 1
      statement = graph.statements.first
      expect(statement.subject.to_s).to eq "http://example.org/resource2"
      expect(statement.predicate).to be_a(RDF::Node)
      expect(statement.predicate.id).to match(/anon/)
      expect(statement.object.to_s).to eq "http://example.org/object"
    end

    it "should create named object bnode" do
      graph = parse("<http://example.org/resource2> <http://example.org/property> _:anon .")
      expect(graph.size).to eq 1
      statement = graph.statements.first
      expect(statement.subject.to_s).to eq "http://example.org/resource2"
      expect(statement.predicate.to_s).to eq "http://example.org/property"
      expect(statement.object).to be_a(RDF::Node)
      expect(statement.object.id).to match(/anon/)
    end

    {
      "three uris"  => "<http://example.org/resource1> <http://example.org/property> <http://example.org/resource2> .",
      "spaces and tabs throughout" => " 	 <http://example.org/resource3> 	 <http://example.org/property>	 <http://example.org/resource2> 	.	 ",
      "line ending with CR NL" => "<http://example.org/resource4> <http://example.org/property> <http://example.org/resource2> .\r\n",
      "literal escapes (1)" => '<http://example.org/resource7> <http://example.org/property> "simple literal" .',
      "literal escapes (2)" => '<http://example.org/resource8> <http://example.org/property> "backslash:\\\\" .',
      "literal escapes (3)" => '<http://example.org/resource9> <http://example.org/property> "dquote:\"" .',
      "literal escapes (4)" => '<http://example.org/resource10> <http://example.org/property> "newline:\n" .',
      "literal escapes (5)" => '<http://example.org/resource11> <http://example.org/property> "return:\r" .',
      "literal escapes (6)" => '<http://example.org/resource12> <http://example.org/property> "tab:\t" .',
      "Space is optional before final . (1)" => ['<http://example.org/resource13> <http://example.org/property> <http://example.org/resource2>.', '<http://example.org/resource13> <http://example.org/property> <http://example.org/resource2> .'],
      "Space is optional before final . (2)" => ['<http://example.org/resource14> <http://example.org/property> "x".', '<http://example.org/resource14> <http://example.org/property> "x" .'],

      "XML Literals as Datatyped Literals (1)" => '<http://example.org/resource21> <http://example.org/property> ""^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (2)" => '<http://example.org/resource22> <http://example.org/property> " "^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (3)" => '<http://example.org/resource23> <http://example.org/property> "x"^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (4)" => '<http://example.org/resource23> <http://example.org/property> "\""^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (5)" => '<http://example.org/resource24> <http://example.org/property> "<a></a>"^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (6)" => '<http://example.org/resource25> <http://example.org/property> "a <b></b>"^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (7)" => '<http://example.org/resource26> <http://example.org/property> "a <b></b> c"^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (8)" => '<http://example.org/resource26> <http://example.org/property> "a\n<b></b>\nc"^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',
      "XML Literals as Datatyped Literals (9)" => '<http://example.org/resource27> <http://example.org/property> "chat"^^<http://www.w3.org/2000/01/rdf-schema#XMLLiteral> .',

      "Plain literals with languages (1)" => '<http://example.org/resource30> <http://example.org/property> "chat"@fr .',
      "Plain literals with languages (2)" => '<http://example.org/resource31> <http://example.org/property> "chat"@en .',

      "Typed Literals" => '<http://example.org/resource32> <http://example.org/property> "abc"^^<http://example.org/datatype1> .',
    }.each_pair do |name, statement|
      specify "test #{name}" do
        graph = parse([statement].flatten.first)
        g2 = RDF::NTriples::Reader.new([statement].flatten.last)
        expect(graph).to be_equivalent_graph(g2, about: "http://a/b", logger: logger, format: :n3)
      end
    end

    it "whitespace in uris" do
      n3 = %{<http: //example.org/\r\nresource3> <http://\texample.org/property> <\nhttp://example.org/resource2\n> .}
      nt = %{<http://example.org/resource3> <http://example.org/property> <http://example.org/resource2> .}
      graph = parse(n3, logger: logger)
      expect(graph).to be_equivalent_graph(nt, logger: logger)
    end

    it "should allow mixed-case language" do
      n3doc = %(:x2 :p "xyz"@en .)
      statement = parse(n3doc).statements.first
      expect(statement.object.to_ntriples).to eq %("xyz"@en)
    end

    it "should create typed literals" do
      n3doc = "<http://example.org/joe> <http://xmlns.com/foaf/0.1/name> \"Joe\"^^<http://www.w3.org/2001/XMLSchema#string> ."
      statement = parse(n3doc).statements.first
      expect(statement.object).to be_literal
    end

    it "should create BNodes" do
      n3doc = "_:a a _:c ."
      statement = parse(n3doc).statements.first
      expect(statement.subject).to be_node
      expect(statement.object).to be_node
    end

    describe "should create URIs" do
      {
        %(<http://example.org/joe> <http://xmlns.com/foaf/0.1/knows> <http://example.org/jane> .) => %(<http://example.org/joe> <http://xmlns.com/foaf/0.1/knows> <http://example.org/jane> .),
        %(<joe> <knows> <jane> .) => %(<http://a/joe> <http://a/knows> <http://a/jane> .),
        %(:joe :knows :jane .) => %(<http://a/b#joe> <http://a/b#knows> <http://a/b#jane> .),
        %(<#D%C3%BCrst>  a  "URI percent ^encoded as C3, BC".) => %(<http://a/b#D%C3%BCrst> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> "URI percent ^encoded as C3, BC" .),
      }.each_pair do |n3, nt|
        it "for '#{n3}'" do
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end
      end

      {
        %(<#Dürst> :knows :jane.) => '<http://a/b#D\u00FCrst> <http://a/b#knows> <http://a/b#jane> .',
        %(:Dürst :knows :jane.) => '<http://a/b#D\u00FCrst> <http://a/b#knows> <http://a/b#jane> .',
        %(:bob :resumé "Bob's non-normalized resumé".) => '<http://a/b#bob> <http://a/b#resumé> "Bob\'s non-normalized resumé" .',
        %(:alice :resumé "Alice's normalized resumé".) => '<http://a/b#alice> <http://a/b#resumé> "Alice\'s normalized resumé" .',
        }.each_pair do |n3, nt|
          it "for '#{n3}'" do
            expect(parse(n3, base_uri: "http://a/b", logger: false)).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
          end
        end

      {
        %(<#Dürst>       a  "URI straight in UTF8".) => %(<http://a/b#D\\u00FCrst> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> "URI straight in UTF8" .),
        %(:a :related :ひらがな .) => %(<http://a/b#a> <http://a/b#related> <http://a/b#\\u3072\\u3089\\u304C\\u306A> .),
      }.each_pair do |n3, nt|
        it "for '#{n3}'" do
          expect(parse(n3, base_uri: "http://a/b", logger: false)).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end
      end
    end

    it "should create URIs" do
      n3doc = "<http://example.org/joe> <http://xmlns.com/foaf/0.1/knows> <http://example.org/jane> ."
      statement = parse(n3doc).statements.first
      expect(statement.subject).to be_uri
      expect(statement.object).to be_uri
    end

    it "should create literals" do
      n3doc = "<http://example.org/joe> <http://xmlns.com/foaf/0.1/name> \"Joe\"."
      statement = parse(n3doc).statements.first
      expect(statement.object).to be_literal
    end
  end

  describe "with n3 grammar" do
    describe "syntactic expressions" do
      it "should create typed literals with pname" do
        n3doc = %(
          @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix foaf: <http://xmlns.com/foaf/0.1/> .
          @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          <http://example.org/joe> foaf:name \"Joe\"^^xsd:string .
        )
        statement = parse(n3doc).statements.first
        expect(statement.object).to be_literal
      end

      it "should use <> as a prefix and as a triple node" do
        n3 = %(@prefix : <> . <> a :a.)
        nt = %(
        <http://a/b> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://a/ba> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should use <#> as a prefix and as a triple node" do
        n3 = %(@prefix : <#> . <#> a :a.)
        nt = %(
        <http://a/b#> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://a/b#a> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate rdf:type for 'a'" do
        n3 = %(@prefix a: <http://foo/a#> . a:b a <http://www.w3.org/2000/01/rdf-schema#resource> .)
        nt = %(<http://foo/a#b> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/01/rdf-schema#resource> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate rdf:type for '@a'", pending: 'deprecated' do
        n3 = %(@prefix a: <http://foo/a#> . a:b @a <http://www.w3.org/2000/01/rdf-schema#resource> .)
        nt = %(<http://foo/a#b> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/01/rdf-schema#resource> .)
        expect(parse(n3, base_uri: "http://a/b", validate: tru)).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate inverse predicate for 'is xxx of'" do
        n3 = %("value" is :prop of :b .)
        nt = %(<http://a/b#b> <http://a/b#prop> "value" .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate inverse predicate for '@is xxx @of'", pending: 'deprecated' do
        n3 = %("value" @is :prop @of :b .)
        nt = %(<http://a/b#b> <http://a/b#prop> "value" .)
        expect(parse(n3, base_uri: "http://a/b", validate: true)).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate inverse predicate for '<- xxx'" do
        n3 = %("value" <- :prop :b .)
        nt = %(<http://a/b#b> <http://a/b#prop> "value" .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate inverse predicate for 'is xxx of' with object list" do
        n3 = %("value" is :prop of :b, :c . )
        nt = %(
        <http://a/b#b> <http://a/b#prop> "value" .
        <http://a/b#c> <http://a/b#prop> "value" .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate inverse predicate for 'is xxx of' with blankNodePropertyList" do
        n3 = %([ is :prop of :George] .)
        nt = %(
        <http://a/b#George> <http://a/b#prop> _:bn .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate inverse predicate for 'is xxx of' with bnode" do
        n3 = %(_:bn is :prop of :George.)
        nt = %(
        <http://a/b#George> <http://a/b#prop> _:bn .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate predicate for 'has xxx'" do
        n3 = %(@prefix a: <http://foo/a#> . a:b has :pred a:c .)
        nt = %(<http://foo/a#b> <http://a/b#pred> <http://foo/a#c> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should generate predicate for '@has xxx'", pending: 'deprecated' do
        n3 = %(@prefix a: <http://foo/a#> . a:b @has :pred a:c .)
        nt = %(<http://foo/a#b> <http://a/b#pred> <http://foo/a#c> .)
        expect(parse(n3, base_uri: "http://a/b", validate: tru)).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create log:implies predicate for '=>'" do
        n3 = %(@prefix a: <http://foo/a#> . _:a => a:something .)
        nt = %(_:a <http://www.w3.org/2000/10/swap/log#implies> <http://foo/a#something> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create log:implies inverse predicate for '<='" do
        n3 = %(@prefix a: <http://foo/a#> . _:a <= a:something .)
        nt = %(<http://foo/a#something> <http://www.w3.org/2000/10/swap/log#implies> _:a .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create owl:sameAs predicate for '='" do
        n3 = %(@prefix a: <http://foo/a#> . _:a = a:something .)
        nt = %(_:a <http://www.w3.org/2002/07/owl#sameAs> <http://foo/a#something> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      {
        %(:a :b 1)  => %(<http://a/b#a> <http://a/b#b> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .),
        %(:a :b -1)  => %(<http://a/b#a> <http://a/b#b> "-1"^^<http://www.w3.org/2001/XMLSchema#integer> .),
        %(:a :b +1)  => %(<http://a/b#a> <http://a/b#b> "+1"^^<http://www.w3.org/2001/XMLSchema#integer> .),
        %(:a :b 1.0)  => %(<http://a/b#a> <http://a/b#b> "1.0"^^<http://www.w3.org/2001/XMLSchema#decimal> .),
        %(:a :b 1.0e1)  => %(<http://a/b#a> <http://a/b#b> "1.0e1"^^<http://www.w3.org/2001/XMLSchema#double> .),
        %(:a :b 1.0e-1)  => %(<http://a/b#a> <http://a/b#b> "1.0e-1"^^<http://www.w3.org/2001/XMLSchema#double> .),
        %(:a :b 1.0e+1)  => %(<http://a/b#a> <http://a/b#b> "1.0e+1"^^<http://www.w3.org/2001/XMLSchema#double> .),
        %(:a :b 1.0E1)  => %(<http://a/b#a> <http://a/b#b> "1.0E1"^^<http://www.w3.org/2001/XMLSchema#double> .),
      }.each_pair do |n3, nt|
        it "should create typed literal for '#{n3}'" do
          expected = RDF::NTriples::Reader.new(nt)
          expect(parse("#{n3} .", base_uri: "http://a/b")).to be_equivalent_graph(expected, about: "http://a/b", logger: logger, format: :n3)
        end
      end

      it "should accept empty localname" do
        n3 = %(: : : .)
        nt = %(<http://a/b#> <http://a/b#> <http://a/b#> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should accept prefix with empty local name" do
        n3 = %(@prefix foo: <http://foo/bar#> . foo: foo: foo: .)
        nt = %(<http://foo/bar#> <http://foo/bar#> <http://foo/bar#> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end
    end

    context "patterns" do
      it "substitutes variable for URI with @forAll" do
        n3 = %(@forAll :x . :x :y :z .)
        g = parse(n3, base_uri: "http://a/b")
        statement = g.statements.first
        expect(statement.subject).to be_variable
        expect(statement.predicate.to_s).to eq "http://a/b#y"
        expect(statement.object.to_s).to eq "http://a/b#z"
      end

      it "substitutes variable for URIs with @forAll" do
        n3 = %(@forAll :x, :y, :z . :x :y :z .)
        g = parse(n3, base_uri: "http://a/b")
        statement = g.statements.first
        expect(statement.subject).to be_variable
        expect(statement.predicate).to be_variable
        expect(statement.object).to be_variable
        expect(statement.subject).not_to equal statement.predicate
        expect(statement.object).not_to equal statement.predicate
        expect(statement.predicate).not_to equal statement.object
      end

      it "creates variable for quickVar" do
        n3 = %(?x :y :z .)
        g = parse(n3, base_uri: "http://a/b")
        statement = g.statements.first
        expect(statement.subject).to be_variable
        expect(statement.predicate).not_to be_variable
        expect(statement.object).not_to be_variable
        expect(statement.subject).not_to equal statement.predicate
        expect(statement.subject).not_to equal statement.object
      end

      it "substitutes node for URI with @forSome" do
        n3 = %(@forSome :x . :x :y :z .)
        g = parse(n3, base_uri: "http://a/b")
        statement = g.statements.first
        expect(statement.subject).to be_variable, logger.to_s
        expect(statement.predicate.to_s).to eq "http://a/b#y"
        expect(statement.object.to_s).to eq "http://a/b#z"
      end

      it "substitutes node for URIs with @forSome" do
        n3 = %(@forSome :x, :y, :z . :x :y :z .)
        g = parse(n3, base_uri: "http://a/b")
        statement = g.statements.first
        expect(statement.subject).to be_variable
        expect(statement.predicate).to be_variable
        expect(statement.object).to be_variable
        expect(statement.subject).not_to equal statement.predicate
        expect(statement.object).not_to equal statement.predicate
        expect(statement.predicate).not_to equal statement.object
      end
    end

    describe "prefixes" do
      it "should not append # for http://foo/bar" do
        n3 = %(@prefix : <http://foo/bar> . :a : :b .)
        nt = %(
        <http://foo/bara> <http://foo/bar> <http://foo/barb> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should not append # for http://foo/bar (sparqlPrefix)" do
        n3 = %(PrEfIx : <http://foo/bar> :a : :b .)
        nt = %(
        <http://foo/bara> <http://foo/bar> <http://foo/barb> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should not append # for http://foo/bar/" do
        n3 = %(@prefix : <http://foo/bar/> . :a : :b .)
        nt = %(
        <http://foo/bar/a> <http://foo/bar/> <http://foo/bar/b> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should not append # for http://foo/bar#" do
        n3 = %(@prefix : <http://foo/bar#> . :a : :b .)
        nt = %(
        <http://foo/bar#a> <http://foo/bar#> <http://foo/bar#b> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should set absolute base" do
        n3 = %(@base <http://foo/bar> . <> :a <b> . <#c> :d </e>.)
        nt = %(
        <http://foo/bar> <http://foo/bar#a> <http://foo/b> .
        <http://foo/bar#c> <http://foo/bar#d> <http://foo/e> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should set absolute base (sparqlBase)" do
        n3 = %(BaSe <http://foo/bar> <> :a <b> . <#c> :d </e>.)
        nt = %(
        <http://foo/bar> <http://foo/bar#a> <http://foo/b> .
        <http://foo/bar#c> <http://foo/bar#d> <http://foo/e> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should set absolute base (trailing /)" do
        n3 = %(@base <http://foo/bar/> . <> :a <b> . <#c> :d </e>.)
        nt = %(
        <http://foo/bar/> <http://foo/bar/a> <http://foo/bar/b> .
        <http://foo/bar/#c> <http://foo/bar/d> <http://foo/e> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should set absolute base (trailing #)" do
        n3 = %(@base <http://foo/bar#> . <> :a <b> . <#c> :d </e>.)
        nt = %(
        <http://foo/bar#> <http://foo/bar#a> <http://foo/b> .
        <http://foo/bar#c> <http://foo/bar#d> <http://foo/e> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should set relative base" do
        n3 = %(
        @base <http://example.org/products/>.
        <> :a <b>, <#c>.
        @base <prod123/>.
        <> :a <b>, <#c>.
        @base <../>.
        <> :a <d>, <#e>.
        )
        nt = %(
        <http://example.org/products/> <http://example.org/products/a> <http://example.org/products/b> .
        <http://example.org/products/> <http://example.org/products/a> <http://example.org/products/#c> .
        <http://example.org/products/prod123/> <http://example.org/products/prod123/a> <http://example.org/products/prod123/b> .
        <http://example.org/products/prod123/> <http://example.org/products/prod123/a> <http://example.org/products/prod123/#c> .
        <http://example.org/products/> <http://example.org/products/a> <http://example.org/products/d> .
        <http://example.org/products/> <http://example.org/products/a> <http://example.org/products/#e> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "returns defined prefixes" do
        n3 = %(
        @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix : <http://test/> .
        :foo a rdfs:Class.
        :bar :d :c.
        :a :d :c.
        )
        reader = RDF::N3::Reader.new(n3, validate: true)
        reader.each {|statement|}
        expect(reader.prefixes).to eq({
          rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
          rdfs: "http://www.w3.org/2000/01/rdf-schema#",
          nil => "http://test/"
        })
      end
    end

    describe "declaration ordering" do
      it "should allow a prefix to be redefined" do
        n3 = %(
        @prefix a: <http://host/A#>.
        a:b a:p a:v .

        @prefix a: <http://host/Z#>.
        a:b a:p a:v .
        )
        nt = %(
        <http://host/A#b> <http://host/A#p> <http://host/A#v> .
        <http://host/Z#b> <http://host/Z#p> <http://host/Z#v> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should process sequential @base declarations (swap base.n3)" do
        n3 = %(
        @base <http://example.com/ontolgies>. <a> :b <foo/bar#baz>.
        @base <path/DFFERENT/>. <a2> :b2 <foo/bar#baz2>.
        @prefix : <#>. <d3> :b3 <e3>.
        )
        nt = %(
        <http://example.com/a> <http://example.com/ontolgies#b> <http://example.com/foo/bar#baz> .
        <http://example.com/path/DFFERENT/a2> <http://example.com/path/DFFERENT/b2> <http://example.com/path/DFFERENT/foo/bar#baz2> .
        <http://example.com/path/DFFERENT/d3> <http://example.com/path/DFFERENT/#b3> <http://example.com/path/DFFERENT/e3> .
        )
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end
    end

    describe "IRIs" do
      {
        "with newlines": {
          n3: %(
            <http://example.com/iri with
            whitespace is
            okay
            > a :testcase .
          ),
          ttl: %(
          <http://example.com/iriwithwhitespaceisokay> a <http://a/b#testcase> .
          )
        },
      }.each do |name, params|
        it name do
          expected = parse(params[:ttl], base_uri: "http://a/b", logger: false)
          expect(parse(params[:n3], base_uri: "http://a/b")).to be_equivalent_graph(expected, about: "http://a/b", logger: logger)
        end
      end
    end

    describe "BNodes" do
      it "should create BNode for identifier with '_' prefix" do
        n3 = %(@prefix a: <http://foo/a#> . _:a a:p a:v .)
        nt = %(_:bnode0 <http://foo/a#p> <http://foo/a#v> .)
        g = parse(n3, base_uri: "http://a/b")
        expect(g).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create BNode for [] as subject" do
        n3 = %(@prefix a: <http://foo/a#> . [] a:p a:v .)
        nt = %(_:bnode0 <http://foo/a#p> <http://foo/a#v> .)
        g = parse(n3, base_uri: "http://a/b")
        expect(g).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create BNode for [] as predicate" do
        n3 = %(@prefix a: <http://foo/a#> . a:s [] a:o .)
        g = parse(n3, base_uri: "http://a/b")
        st = g.statements.first
        expect(st.predicate).to be_a_node
      end

      it "should create BNode for [] as object" do
        n3 = %(@prefix a: <http://foo/a#> . a:s a:p [] .)
        nt = %(<http://foo/a#s> <http://foo/a#p> _:bnode0 .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create BNode for [] as statement" do
        n3 = %([:a :b] .)
        nt = %(_:bnode0 <http://a/b#a> <http://a/b#b> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      it "should create statements with BNode subjects using [ pref obj]" do
        n3 = %(@prefix a: <http://foo/a#> . [ a:p a:v ] .)
        nt = %(_:bnode0 <http://foo/a#p> <http://foo/a#v> .)
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
      end

      context "blankNodePropertyList" do
        it "should create BNode as a single object" do
          n3 = %(@prefix a: <http://foo/a#> . a:b a:oneRef [ a:pp "1" ; a:qq "2" ] .)
          nt = %(
          _:bnode0 <http://foo/a#pp> "1" .
          _:bnode0 <http://foo/a#qq> "2" .
          <http://foo/a#b> <http://foo/a#oneRef> _:bnode0 .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should create a shared BNode" do
          n3 = %(
          @prefix a: <http://foo/a#> .

          a:b1 a:twoRef _:a .
          a:b2 a:twoRef _:a .

          _:a :pred [ a:pp "1" ; a:qq "2" ].
          )
          nt = %(
          <http://foo/a#b1> <http://foo/a#twoRef> _:a .
          <http://foo/a#b2> <http://foo/a#twoRef> _:a .
          _:bnode0 <http://foo/a#pp> "1" .
          _:bnode0 <http://foo/a#qq> "2" .
          _:a :pred _:bnode0 .
          )
          expected = RDF::Graph.new {|g| g << RDF::N3::Reader.new(nt, base_uri: "http://a/b")}
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(expected, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should create nested BNodes" do
          n3 = %(
          @prefix a: <http://foo/a#> .

          a:a a:p [ a:p2 [ a:p3 "v1" , "v2" ; a:p4 "v3" ] ; a:p5 "v4" ] .
          )
          nt = %(
          _:bnode0 <http://foo/a#p3> "v1" .
          _:bnode0 <http://foo/a#p3> "v2" .
          _:bnode0 <http://foo/a#p4> "v3" .
          _:bnode1 <http://foo/a#p2> _:bnode0 .
          _:bnode1 <http://foo/a#p5> "v4" .
          <http://foo/a#a> <http://foo/a#p> _:bnode1 .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end
      end

      describe "property lists" do
        it "should parse property list" do
          n3 = %(
          @prefix a: <http://foo/a#> .

          a:b a:p1 "123" ; a:p1 "456" .
          a:b a:p2 a:v1 ; a:p3 a:v2 .
          )
          nt = %(
          <http://foo/a#b> <http://foo/a#p1> "123" .
          <http://foo/a#b> <http://foo/a#p1> "456" .
          <http://foo/a#b> <http://foo/a#p2> <http://foo/a#v1> .
          <http://foo/a#b> <http://foo/a#p3> <http://foo/a#v2> .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end
      end

      describe "lists" do
        it "should parse empty list" do
          n3 = %(@prefix :<http://example.com/>. :empty :set ().)
          nt = %(
          <http://example.com/empty> <http://example.com/set> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .)
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should parse list with single element" do
          n3 = %(@prefix :<http://example.com/>. :gregg :wrote ("RdfContext").)
          nt = %(
          _:bnode0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "RdfContext" .
          _:bnode0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          <http://example.com/gregg> <http://example.com/wrote> _:bnode0 .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should parse list with multiple elements" do
          n3 = %(@prefix :<http://example.com/>. :gregg :name ("Gregg" "Barnum" "Kellogg").)
          nt = %(
          _:bnode0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Gregg" .
          _:bnode0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:bnode1 .
          _:bnode1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Barnum" .
          _:bnode1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:bnode2 .
          _:bnode2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Kellogg" .
          _:bnode2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          <http://example.com/gregg> <http://example.com/name> _:bnode0 .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should parse unattached lists" do
          n3 = %(
          @prefix a: <http://foo/a#> .

          ("1" "2" "3") .
          # This is not a statement.
          () .
          )
          nt = %(
          _:bnode0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "1" .
          _:bnode0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:bnode1 .
          _:bnode1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "2" .
          _:bnode1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:bnode2 .
          _:bnode2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "3" .
          _:bnode2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should add property to nil list" do
          n3 = %(@prefix a: <http://foo/a#> . () a:prop "nilProp" .)
          nt = %(<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> <http://foo/a#prop> "nilProp" .)
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end

        it "should parse with compound items" do
          n3 = %(
            @prefix a: <http://foo/a#> .
            a:a a:p (
              [ a:p2 "v1" ]
              <http://resource1>
              <http://resource2>
              ("inner list")
            ) .
            <http://resource1> a:p "value" .
          )
          g = parse(n3, base_uri: "http://a/b")
          expect(g.subjects.to_a.length).to eq 8
          n = g.first_object(subject: RDF::URI.new("http://foo/a#a"), predicate: RDF::URI.new("http://foo/a#p"))
          expect(n).to be_node
          seq = RDF::List.new(subject: n, graph: g)
          expect(seq.to_a.length).to eq 4
          expect(seq.first).to be_node
          expect(seq.second).to eq RDF::URI.new("http://resource1")
          expect(seq.third).to eq RDF::URI.new("http://resource2")
          expect(seq.fourth).to be_node
        end
      end

      context "property paths" do
        {
          "subject x!p": [
            %(:x2!:y2 :p2 "3" .),
            %(:x2 :y2 _:bnode0 . _:bnode0 :p2 "3" .)
          ],
          "subject x^p": [
            %(:x2^:y2 :p2 "3" .),
            %(_:bnode0 :y2 :x2 . _:bnode0 :p2 "3" .)
          ],
          "alberts mother inverse of metor to auntieAnne": [
            %(:albert!:mother :mentor!:inverse :auntieAnne .),
            %(
              :albert :mother _:bnode0 .
              _:bnode0 _:pred0 :auntieAnne .
              :mentor :inverse _:pred0 . 
            )
          ],
          "albert doesnt admire grumpy": [
            %(:albert :admires!:converse :grumpy .),
            %(:albert _:pred0 :grumpy . :admires :converse _:pred0 .)
          ],
          "1+2=3": [
            %{("1" "2")!:sum a :THREE.},
            %{("1" "2") :sum _:bnode0 . _:bnode0 a :THREE .}
          ],
          "relatedTo": [
            %{(:a!:b :c^:d) :relatedTo (:e!:f!:g ) .},
            %{
              :a :b _:bnode0 .
              _:bnode1 :d :c .
              :e :f _:bnode2 .
              _:bnode2 :g _:bnode3 .
              (_:bnode0 _:bnode1) :relatedTo (_:bnode3) .
            }
          ],
          "joes mothers offices zip": [
            %{:joe!:mother!:office!:zip .},
            %{:joe :mother [:office [:zip []]] .}
          ],
          "Anyone whose mother is Joe's mother": [
            %{:joe!:mother^:mother .},
            %{:joe :mother _:bnode0 . [:mother _:bnode0] .}
          ],
          "path as object(1)": [
            %{:a  :b "lit"^:c.},
            %{:a :b [:c "lit"] .}
          ],
          "path as object(2)": [
            %(:r :p :o!:p1!:p2 .),
            %{:o :p1 [:p2 _:bnode1] . :r :p _:bnode1 .}
          ]
        }.each do |title, (n3, res)|
          it title do
            expected = RDF::Graph.new {|g| g << RDF::N3::Reader.new(res, base_uri: "http://a/b")}
            expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(expected, logger: logger, format: :n3)
          end
        end
      end
    end

    describe "formulae" do
      before(:each) { @repo = RDF::Repository.new }

      it "creates an RDF::Node instance for formula" do
        n3 = %(:a :b {} .)
        nq = %(:a :b _:c .)
        result = parse(n3, repo: @repo, base_uri: "http://a/b")
        expected = parse(nq, repo: @repo, base_uri: "http://a/b")
        expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
      end

      it "adds statements with graph_name" do
        n3 = %(:a :b {[:c :d]} .)
        trig = %(<#a> <#b> _:c . _:c {[<#c> <#d>] .})
        result = parse(n3, repo: @repo, base_uri: "http://a/b")
        expected = RDF::Repository.new {|r| r << RDF::TriG::Reader.new(trig, base_uri: "http://a/b")}
        expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
      end

      it "creates quads for patterns when added to a repository" do
        n3 = %(
          @prefix x: <http://example.org/x-ns/#> .
          @prefix log: <http://www.w3.org/2000/10/swap/log#> .
          @prefix dc: <http://purl.org/dc/elements/1.1/#> .
          { [ x:firstname  "Ora" ] dc:wrote [ dc:title  "Moby Dick" ] } a log:falsehood .
        )
        trig = %(
          @prefix x: <http://example.org/x-ns/#> .
          @prefix log: <http://www.w3.org/2000/10/swap/log#> .
          @prefix dc: <http://purl.org/dc/elements/1.1/#> .
          _:f a log:falsehood .
          _:f {
            [ x:firstname  "Ora" ] dc:wrote [ dc:title  "Moby Dick" ] .
          }
        )
        result = parse(n3, repo: @repo, base_uri: "http://a/b")
        expected = RDF::Repository.new {|r| r << RDF::TriG::Reader.new(trig, base_uri: "http://a/b")}
        expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
      end

      it "creates unique bnodes within different formula (bnodes)" do
        n3 = %(
          _:a a :Thing .
          {_:a a :Thing} => {_:a a :Thing} .
        )
        result = parse(n3, repo: @repo, base_uri: "http://a/b")
        statements = result.statements
        expect(statements.length).to produce(4, logger)
        # All three bnodes should be distinct
        nodes_of_a = statements.map(&:to_a).flatten.select {|r| r.node? && r.to_s.start_with?('_:a')}
        expect(nodes_of_a.uniq.count).to produce(3, logger)
      end

      it "creates unique bnodes within different formula (quickvar)" do
        n3 = %(
          :a a :Thing .
          {?a a :Thing} => {?a a :Thing} .
        )
        result = parse(n3, repo: @repo, base_uri: "http://a/b")
        statements = result.statements
        expect(statements.length).to produce(4, logger)
        # only one variable
        variables = statements.map(&:to_a).flatten.select {|r| r.variable?}
        expect(variables.uniq.count).to produce(1, logger)
      end

      {
        "empty subject" => {
          input: %({} <b> <c> .),
          expect: %({} <http://a/b> <http://a/c> .)
        },
        "empty object" => {
          input: %(<a> <b> {} .),
          expect: %(<http://a/a> <http://a/b> {} .)
        },
        "as subject with constant content" => {
          input: %({<x> <y> <z>} <b> <c> .),
          expect: %({<http://a/x> <http://a/y> <http://a/z>} <http://a/b> <http://a/c> .),
        },
        "as object with constant content" => {
          input: %(<a> <b> {<x> <y> <z>} .),
          expect: %(<http://a/a> <http://a/b> {<http://a/x> <http://a/y> <http://a/z>} .),
        },
      }.each do |name, params|
        it name do
          result = parse(params[:expect], base_uri: "http://a/b", logger: false)
          expect(parse(params[:input], base_uri: "http://a/b")).to be_equivalent_graph(result, logger: logger, format: :n3)
        end
      end

      context "contexts" do
        before(:each) do
          n3 = %(
            # Test data in notation3 http://www.w3.org/DesignIssues/Notation3.html
            #
            @prefix u: <http://www.example.org/utilities#> .
            @prefix : <#> .

            :assumption = { :fred u:knows :john .
                            :john u:knows :mary .} .

            :conclusion = { :fred u:knows :mary . } .

            # The empty context is trivially true.
            # Check that we can input it and output it!

            :trivialTruth = { }.

            # ENDS
          )
          @repo = RDF::Repository.new
          parse(n3, repo: @repo, base_uri: "http://a/b")
        end
        subject {@repo}

        it "assumption graph has 2 statements" do
          tt = subject.first(subject: RDF::URI.new("http://a/b#assumption"), predicate: RDF::OWL.sameAs)
          expect(tt.object).to be_node
          expect(subject.query({graph_name: tt.object}).to_a.length).to eq 2
        end

        it "conclusion graph has 1 statements" do
          tt = subject.first(subject: RDF::URI.new("http://a/b#conclusion"), predicate: RDF::OWL.sameAs)
          expect(tt.object).to be_node
          expect(subject.query({graph_name: tt.object}).to_a.length).to eq 1
        end

        it "trivialTruth equivalent to empty graph" do
          tt = subject.first(subject: RDF::URI.new("http://a/b#trivialTruth"), predicate: RDF::OWL.sameAs)
          expect(tt.object).to be_node
          subject.query({graph_name: tt.object}) do |s|
            puts "statement: #{s}"
          end
        end

      end
    end

    describe "object lists" do
      it "should create 2 statements for simple list" do
        n3 = %(:a :b :c, :d .)
        nt = %(<http://a/b#a> <http://a/b#b> <http://a/b#c> . <http://a/b#a> <http://a/b#b> <http://a/b#d> .)
        expected = RDF::Graph.new {|g| g << RDF::N3::Reader.new(nt, base_uri: "http://a/b")}
        expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(expected, about: "http://a/b", logger: logger, format: :n3)
      end
    end

    # n3p tests taken from http://inamidst.com/n3p/test/
    describe "with real data tests" do
      dirs = %w(misc lcsh rdflib n3p)
      dirs.each do |dir|
        dir_name = File.join(File.dirname(__FILE__), '..', 'test', 'n3_tests', dir, '*.n3')
        Dir.glob(dir_name).each do |n3|
          it "#{dir} #{n3}" do
            test_file(n3)
          end
        end
      end
    end

    describe "with AggregateGraph tests" do
      describe "with a type" do
        it "should have 3 namespaces" do
          n3 = %(
          @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
          @prefix : <http://test/> .
          :foo a rdfs:Class.
          :bar :d :c.
          :a :d :c.
          )
          nt = %(
          <http://test/foo> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/01/rdf-schema#Class> .
          <http://test/bar> <http://test/d> <http://test/c> .
          <http://test/a> <http://test/d> <http://test/c> .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end
      end

      describe "with blank clause" do
        it "should have 4 namespaces" do
          n3 = %(
          @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
          @prefix : <http://test/> .
          @prefix log: <http://www.w3.org/2000/10/swap/log#>.
          :foo a rdfs:Resource.
          :bar rdfs:isDefinedBy [ a log:Formula ].
          :a :d :e.
          )
          nt = %(
          <http://test/foo> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/01/rdf-schema#Resource> .
          _:g2160128180 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/swap/log#Formula> .
          <http://test/bar> <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> _:g2160128180 .
          <http://test/a> <http://test/d> <http://test/e> .
          )
          expect(parse(n3, base_uri: "http://a/b")).to be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
        end
      end

      describe "with empty subject" do
        before(:each) do
          @graph = parse(%(
          @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
          @prefix log: <http://www.w3.org/2000/10/swap/log#>.
          @prefix : <http://test/> .
          <> a log:N3Document.
          ), base_uri: "http://test/")
        end

        it "should have 4 namespaces" do
          nt = %(
          <http://test/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/swap/log#N3Document> .
          )
          expect(@graph).to be_equivalent_graph(nt, about: "http://test/", logger: logger, format: :n3)
        end

        it "should have default subject" do
          expect(@graph.size).to eq 1
          expect(@graph.statements.first.subject.to_s).to eq "http://test/"
        end
      end
    end
  end

  describe "canonicalization" do
#    {
#      "<http://foo>"                 =>  "<http://foo>",
#      "<http://foo/a>"               => "<http://foo/a>",
#      "<http://foo#a>"               => "<http://foo#a>",
#
#      "<http://foo/>"                =>  "<http://foo/>",
#      "<http://foo/#a>"              => "<http://foo/#a>",
#
#      "<http://foo#>"                =>  "<http://foo#>",
#      "<http://foo#a>"               => "<http://foo/a>",
#      "<http://foo#/a>"              => "<http://foo/a>",
#      "<http://foo##a>"              => "<http://foo#a>",
#
#      "<http://foo/bar>"             =>  "<http://foo/bar>",
#      "<http://foo/bar>"             => "<http://foo/a>",
#      "<http://foo/bar/a>"           => "<http://foo/a>",
#      "<http://foo/bar#a>"           => "<http://foo/bar#a>",
#
#      "<http://foo/bar/>"            =>  "<http://foo/bar/>",
#      "<http://foo/bar/a>"           => "<http://foo/bar/a>",
#      "<http://foo/bar//a>"          => "<http://foo/a>",
#      "<http://foo/bar/#a>"          => "<http://foo/bar/#a>",
#
#      "<http://foo/bar#>"            =>  "<http://foo/bar#>",
#      "<http://foo/bar#a>"           => "<http://foo/a>",
#      "<http://foo/bar#/a>"          => "<http://foo/a>",
#      "<http://foo/bar##a>"          => "<http://foo/bar#a>",
#
#      "<http://foo/bar##D%C3%BCrst>" => "<http://foo/bar#D%C3%BCrst>",
#      "<http://foo/bar##Dürst>"      => "<http://foo/bar#D\\u00FCrst>",
#    }.each_pair do |input, result|
#      it "returns subject #{result} given #{input}" do
#        n3 = %(#{input} a :b)
#        nt = %(#{result} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://a/b#b> .)
#        parse(n3, base_uri: "http://a/b", canonicalize: true).should be_equivalent_graph(nt, about: "http://a/b", logger: logger, format: :n3)
#      end
#    end

    {
      %("+1"^^xsd:integer) => %("1"^^<http://www.w3.org/2001/XMLSchema#integer>),
      %(+1) => %("1"^^<http://www.w3.org/2001/XMLSchema#integer>),
      %(true) => %("true"^^<http://www.w3.org/2001/XMLSchema#boolean>),
      %("lang"@EN) => %("lang"@en),
    }.each_pair do |input, result|
      it "returns object #{result} given #{input}" do
        n3 = %(@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . :a :b #{input} .)
        nt = %(<http://a/b#a> <http://a/b#b> #{result} .)
        expected = RDF::Graph.new {|g| g << RDF::N3::Reader.new(nt, base_uri: "http://a/b")}
        expect(parse(n3, base_uri: "http://a/b", canonicalize: true)).to be_equivalent_graph(expected, about: "http://a/b", logger: logger, format: :n3)
      end
    end
  end

  describe "validation" do
    [
      %(:y :p1 "xyz"^^xsd:integer .),
      %(:y :p1 "12xyz"^^xsd:integer .),
      %(:y :p1 "xy.z"^^xsd:double .),
      %(:y :p1 "+1.0z"^^xsd:double .),
      %(:a :b .),
      #%(:a "literal value" :b .),
      %(@keywords prefix. :e prefix :f .),
    ].each do |n3|
      it "should raise ReaderError for '#{n3}'" do
        expect {
          parse("@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{n3}", base_uri: "http://a/b", validate: true)
        }.to raise_error(RDF::ReaderError)
      end
    end

    [
      %(:y _:p1 "z" .),
      %("y" :p1 "z" .),
    ].each do |n3|
      it "'#{n3}' is valid" do
        expect {
          parse("@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{n3}", base_uri: "http://a/b", validate: true)
        }.not_to raise_error
      end
    end
  end

  it "should parse rdf_core testcase" do
    sampledoc = <<-EOF;
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/Manifest.rdf#test001> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#PositiveParserTest> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/Manifest.rdf#test001> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#approval> <http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2002Mar/0235.html> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/Manifest.rdf#test001> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#inputDocument> <http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/test001.rdf> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/Manifest.rdf#test001> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#issue> <http://www.w3.org/2000/03/rdf-tracking/#rdfms-xml-base> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/Manifest.rdf#test001> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#outputDocument> <http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/test001.nt> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/Manifest.rdf#test001> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#status> "APPROVED" .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/test001.nt> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#NT-Document> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/xmlbase/test001.rdf> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema#RDF-XML-Document> .
EOF
    graph = parse(sampledoc, base_uri: "http://www.w3.org/2000/10/rdf-tests/rdfcore/amp-in-url/Manifest.rdf")

    expect(graph).to be_equivalent_graph(sampledoc,
      about: "http://www.w3.org/2000/10/rdf-tests/rdfcore/amp-in-url/Manifest.rdf",
      logger: logger,
      format: :n3
    )
  end

  def parse(input, **options)
    options = {
      logger: logger,
      validate: false,
      canonicalize: false,
    }.merge(options)
    repo = options[:repo] || [].extend(RDF::Enumerable, RDF::Queryable)
    RDF::N3::Reader.new(input, **options).each_statement do |statement|
      repo << statement
    end
    repo
  end

  def test_file(filepath)
    n3_string = File.read(filepath)
    @graph = parse(File.open(filepath), base_uri: "file:#{filepath}")

    nt_string = File.read(filepath.sub('.n3', '.nt'))
    expect(@graph).to be_equivalent_graph(nt_string,
      about: "file:#{filepath}",
      logger: logger,
      format: :n3)
  end
end
