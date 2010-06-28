# coding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'nokogiri'

describe RDF::Literal do
  require 'nokogiri' rescue nil

  before :each do 
    @new = Proc.new { |*args| RDF::Literal.new(*args) }
  end

  describe "XML Literal" do
    describe "with no namespace" do
      subject { @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral) }
      it "should return input" do subject.to_s.should == "foo <sup>bar</sup> baz!" end

      it "should be equal if they have the same contents" do
        should == @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral)
      end
    end

    describe "with a namespace" do
      subject {
        @new.call("foo <dc:sup>bar</dc:sup> baz!", :datatype => RDF.XMLLiteral,
                      :namespaces => {"dc" => RDF::DC.to_s})
      }

      it "should add namespaces" do subject.to_s.should == "foo <dc:sup xmlns:dc=\"http://purl.org/dc/terms/\">bar</dc:sup> baz!" end

      describe "and language" do
        subject {
          @new.call("foo <dc:sup>bar</dc:sup> baz!", :datatype => RDF.XMLLiteral,
                        :namespaces => {"dc" => RDF::DC.to_s},
                        :language => :fr)
        }

        it "should add namespaces and language" do subject.to_s.should == "foo <dc:sup xmlns:dc=\"http://purl.org/dc/terms/\" xml:lang=\"fr\">bar</dc:sup> baz!" end
      end

      describe "and language with an existing language embedded" do
        subject {
          @new.call("foo <dc:sup>bar</dc:sup><dc:sub xml:lang=\"en\">baz</dc:sub>",
                        :datatype => RDF.XMLLiteral,
                        :namespaces => {"dc" => RDF::DC.to_s},
                        :language => :fr)
        }

        it "should add namespaces and language" do subject.to_s.should == "foo <dc:sup xmlns:dc=\"http://purl.org/dc/terms/\" xml:lang=\"fr\">bar</dc:sup><dc:sub xmlns:dc=\"http://purl.org/dc/terms/\" xml:lang=\"en\">baz</dc:sub>" end
      end
    end

    describe "with a default namespace" do
      subject {
        @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                      :namespaces => {"" => RDF::DC.to_s})
      }

      it "should add namespace" do subject.to_s.should == "foo <sup xmlns=\"http://purl.org/dc/terms/\">bar</sup> baz!" end
    end
  end if defined?(::Nokogiri)
end
