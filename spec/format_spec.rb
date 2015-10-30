$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/format'

describe RDF::N3::Format do
  it_behaves_like 'an RDF::Format' do
    let(:format_class) {RDF::N3::Format}
  end

  describe ".for" do
    formats = [
      :n3,
      'etc/doap.n3',
      {file_name:      'etc/doap.n3'},
      {file_extension: 'n3'},
      {content_type:   'text/n3'},
      {content_type:   'text/rdf+n3'},
      {content_type:   'application/rdf+n3'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Format.for(arg)).to eq described_class
      end
    end

    {
      turtle:         "@prefix foo: <bar> .\n foo:a foo:b <c> .",
      n3:             "@prefix foo: <bar> .\nfoo:bar = {<a> <b> <c>} .",
      default_prefix: ':a :b :c .',
    }.each do |sym, str|
      it "does not detect #{sym}" do
        expect(described_class.for {str}).not_to eq described_class
      end
    end

    it "discovers 'notation3'" do
      expect(RDF::Format.for(:notation3).reader).to eq RDF::N3::Reader
      expect(RDF::Format.for(:notation3).writer).to eq RDF::N3::Writer
    end
  end

  describe "#to_sym" do
    specify {expect(described_class.to_sym).to eq :n3}
  end

  describe ".detect" do
    {
      ntriples:       "<a> <b> <c> .",
      literal:        '<a> <b> "literal" .',
      multi_line:     '<a>\n  <b>\n  "literal"\n .',
      turtle:         "@prefix foo: <bar> .\n foo:a foo:b <c> .",
      n3:             "@prefix foo: <bar> .\nfoo:bar = {<a> <b> <c>} .",
      default_prefix: ':a :b :c .',
    }.each do |sym, str|
      it "does not detect #{sym}" do
        expect(described_class.detect(str)).to be_falsey
      end
    end

    {
      nquads: "<a> <b> <c> <d> . ",
      rdfxml: '<rdf:RDF about="foo"></rdf:RDF>',
      jsonld: '{"@context" => "foo"}',
      rdfa:   '<div about="foo"></div>',
      microdata: '<div itemref="bar"></div>',
    }.each do |sym, str|
      it "does not detect #{sym}" do
        expect(described_class.detect(str)).to be_falsey
      end
    end
  end
end
