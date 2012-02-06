$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/format'

describe RDF::N3::Format do
  before :each do
    @format_class = RDF::N3::Format
  end

  it_should_behave_like RDF_Format

  describe ".for" do
    formats = [
      :n3,
      'etc/doap.n3',
      {:file_name      => 'etc/doap.n3'},
      {:file_extension => 'n3'},
      {:content_type   => 'text/n3'},
      {:content_type   => 'text/rdf+n3'},
      {:content_type   => 'application/rdf+n3'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        RDF::Format.for(arg).should == @format_class
      end
    end

    {
      :turtle         => "@prefix foo: <bar> .\n foo:a foo:b <c> .",
      :n3             => "@prefix foo: <bar> .\nfoo:bar = {<a> <b> <c>} .",
      :default_prefix => ':a :b :c .',
    }.each do |sym, str|
      it "detects #{sym}" do
        @format_class.for {str}.should == @format_class
      end
    end

    it "should discover 'notation3'" do
      RDF::Format.for(:notation3).reader.should == RDF::N3::Reader
      RDF::Format.for(:notation3).writer.should == RDF::N3::Writer
    end
  end

  describe "#to_sym" do
    specify {@format_class.to_sym.should == :n3}
  end

  describe ".detect" do
    {
      :ntriples       => "<a> <b> <c> .",
      :literal        => '<a> <b> "literal" .',
      :multi_line     => '<a>\n  <b>\n  "literal"\n .',
      :turtle         => "@prefix foo: <bar> .\n foo:a foo:b <c> .",
      :n3             => "@prefix foo: <bar> .\nfoo:bar = {<a> <b> <c>} .",
      :default_prefix => ':a :b :c .',
    }.each do |sym, str|
      it "detects #{sym}" do
        @format_class.detect(str).should be_true
      end
    end

    {
      :nquads => "<a> <b> <c> <d> . ",
      :rdfxml => '<rdf:RDF about="foo"></rdf:RDF>',
      :jsonld => '{"@context" => "foo"}',
      :rdfa   => '<div about="foo"></div>',
      :microdata => '<div itemref="bar"></div>',
    }.each do |sym, str|
      it "does not detect #{sym}" do
        @format_class.detect(str).should be_false
      end
    end
  end
end
