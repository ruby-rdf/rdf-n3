# coding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'date'
require 'time'
require 'nokogiri'

describe RDF::Literal do
  describe "an untyped string" do
    subject {RDF::Literal.new("gregg")}
    it "should be equal if they have the same contents" do should == RDF::Literal.new("gregg") end
    it "should not be equal if they do not have the same contents" do should_not == RDF::Literal.new("tim") end
    it "should match a string" do should == "gregg" end
    it "should return a string using to_s" do subject.to_s.should == %("gregg") end
    
    describe "should handle specific cases" do
      {
        '"Gregg"'                     => RDF::Literal.new("Gregg"),
        '"\u677E\u672C \u540E\u5B50"' => RDF::Literal.new("松本 后子"),
        '"D\u00FCrst"'                => RDF::Literal.new("Dürst"),
      }.each_pair do |encoded, literal|
        it "should encode '#{literal.value}'" do
          literal.to_s.should == encoded
        end
      end

      # Ruby 1.9 only
      {
         '"\U00015678another"'         => RDF::Literal.new("\u{15678}another"),
       }.each_pair do |encoded, literal|
         it "should encode '#{literal.value}'" do
           literal.to_s.should == encoded
         end
       end if defined?(::Encoding)
    end

    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"gregg\"" end
    end

    describe "with extended characters" do
      subject { RDF::Literal.new("松本 后子") }
      
      describe "encodings" do
        it "should return n3" do subject.to_s.should == '"\u677E\u672C \u540E\u5B50"' end
      end
    end
    
    describe "with a language" do
      subject { RDF::Literal.new("gregg", :language => "en") }

      it "should accept a language tag" do
        subject.language.should == :en
      end
  
      it "should be equal if they have the same contents and language" do
        should == RDF::Literal.new("gregg", :language => "en")
      end
  
      it "should not be equal if they do not have the same contents" do
        should_not == RDF::Literal.new("tim", :language => "en")
      end
    
      it "should not be equal if they do not have the same language" do
        should_not == RDF::Literal.new("gregg", :language => "fr")
      end

      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"gregg\"@en" end
      end

      it "should normalize language tags to lower case" do
        f = RDF::Literal.new("gregg", :language => "EN")
        f.language.should == :en
      end
    end
  end
  
  describe "a typed string" do
    subject { RDF::Literal.new("gregg", :datatype => RDF::XSD.string) }
    
    it "accepts an encoding" do
      subject.datatype.to_s.should == RDF::XSD.string.to_s
    end

    it "should be equal if they have the same contents and datatype" do
      should == RDF::Literal.new("gregg", :datatype => RDF::XSD.string)
    end

    it "should not be equal if they do not have the same contents" do
      should_not == RDF::Literal.new("tim", :datatype => RDF::XSD.string)
    end

    it "should not be equal if they do not have the same datatype" do
      should_not == RDF::Literal.new("gregg", :datatype => RDF::XSD.token)
    end

    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"gregg\"^^<http://www.w3.org/2001/XMLSchema#string>" end
    end
  end
  
  describe "a boolean" do
    subject { RDF::Literal.new(true, :datatype => RDF::XSD.boolean) }
    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"true\"^^<http://www.w3.org/2001/XMLSchema#boolean>" end
    end

    it "should infer type" do
      int = RDF::Literal.new(true)
      int.datatype.should == RDF::XSD.boolean
    end

    it "should have string contents" do subject.value.should == "true" end
    it "should have native contents" do subject.object.should == true end
  end
    
  describe "an integer" do
    subject { RDF::Literal.new(5, :datatype => RDF::XSD.int) }
    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"5\"^^<http://www.w3.org/2001/XMLSchema#int>" end
    end

    it "should infer type" do
      int = RDF::Literal.new(15)
      int.datatype.should == RDF::XSD.integer
    end

    it "should have string contents" do subject.value.should == "5" end
    it "should have native contents" do subject.object.should == 5 end
  end
    
  describe "a float" do
    subject { RDF::Literal.new(15.4, :datatype => RDF::XSD.float) }
    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"15.4\"^^<http://www.w3.org/2001/XMLSchema#float>" end
    end

    it "should infer type" do
      float = RDF::Literal.new(15.4)
      float.datatype.should == RDF::XSD.double
    end

    it "should have string contents" do subject.value.should == "15.4" end
    it "should have native contents" do subject.object.should == 15.4 end
  end

  describe "a date" do
    before(:each) { @value = Date.parse("2010-01-02Z") }
    subject { RDF::Literal.new(@value, :datatype => RDF::XSD.date) }
    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"2010-01-02Z\"^^<http://www.w3.org/2001/XMLSchema#date>" end
    end

    it "should infer type" do
      int = RDF::Literal.new(@value)
      int.datatype.should == RDF::XSD.date
    end

    it "should have string contents" do subject.value.should == "2010-01-02Z" end
    it "should have native contents" do subject.object.should ==  @value end
  end
  
  describe "a dateTime" do
    before(:each) { @value = DateTime.parse('2010-01-03T01:02:03Z') }
    subject { RDF::Literal.new(@value, :datatype => RDF::XSD.dateTime) }
    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"2010-01-03T01:02:03Z\"^^<http://www.w3.org/2001/XMLSchema#dateTime>" end
    end
    
    it "should infer type" do
      int = RDF::Literal.new(@value)
      int.datatype.should == RDF::XSD.dateTime
    end

    it "should have string contents" do subject.value.should == "2010-01-03T01:02:03Z" end
    it "should have native contents" do subject.object.should ==  @value end
  end
  
  describe "a time" do
    before(:each) { @value = Time.parse('01:02:03Z') }
    subject { RDF::Literal.new(@value, :datatype => RDF::XSD.time) }
    describe "encodings" do
      it "should return n3" do subject.to_s.should == "\"01:02:03Z\"^^<http://www.w3.org/2001/XMLSchema#time>" end
    end
    
    it "should infer type" do
      int = RDF::Literal.new(@value)
      int.datatype.should == RDF::XSD.time
    end

    it "should have string contents" do subject.value.should == "01:02:03Z" end
    it "should have native contents" do subject.object.should ==  @value end
  end
  
  describe "XML Literal" do
    describe "with no namespace" do
      subject { RDF::Literal.new("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral) }
      it "should indicate xmlliteral?" do
        subject.xmlliteral?.should == true
      end
      
      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"foo <sup>bar</sup> baz!\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
      end
      
      it "should be equal if they have the same contents" do
        should == RDF::Literal.new("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral)
      end

      it "should be a XMLLiteral encoding" do
        subject.datatype.should == RDF.XMLLiteral
      end
    end
      
    describe "with a namespace" do
      subject {
        RDF::Literal.new("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                      :namespaces => {"dc" => RDF::DC.to_s})
      }
    
      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"foo <sup>bar</sup> baz!\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
      end
      
      describe "and language" do
        subject {
          RDF::Literal.new("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                        :namespaces => {"dc" => RDF::DC.to_s},
                        :language => :fr)
        }

        describe "encodings" do
          it "should return n3" do subject.to_s.should == "\"foo <sup xml:lang=\\\"fr\\\">bar</sup> baz!\"\^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
        end
      end
      
      describe "and language with an existing language embedded" do
        subject {
          RDF::Literal.new("foo <sup>bar</sup><sub xml:lang=\"en\">baz</sub>",
                        :datatype => RDF.XMLLiteral,
                        :language => :fr)
        }

        describe "encodings" do
          it "should return n3" do subject.to_s.should == "\"foo <sup xml:lang=\\\"fr\\\">bar</sup><sub xml:lang=\\\"en\\\">baz</sub>\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
        end
      end

    describe "with a default namespace" do
      subject {
        RDF::Literal.new("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                      :namespaces => {"" => RDF::DC.to_s})
      }
    
      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"foo <sup xmlns=\\\"http://purl.org/dc/terms/\\\">bar</sup> baz!\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
      end
    end
    
    describe "with multiple namespaces" do
      subject {
        RDF::Literal.new("foo <sup xmlns:dc=\"http://purl.org/dc/terms/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">bar</sup> baz!", :datatype => RDF.XMLLiteral)
      }
      it "should ignore namespace order" do
        g = RDF::Literal.new("foo <sup xmlns:dc=\"http://purl.org/dc/terms/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">bar</sup> baz!", :datatype => RDF.XMLLiteral)
        should == g
      end
    end
  end
  
  describe "an n3 literal" do
    {
      "Gregg"          => 'Gregg',
      "Dürst"          => 'D\u00FCrst',
      "simple literal" => 'simple literal',
      "backslash:\\"   => 'backslash:\\\\',
      "dquote:\""      => 'dquote:\\"',
      "newline:\n"     => 'newline:\\n',
      "return:\r"      => 'return:\\r',
      "tab:\t"         => 'tab:\\t',
    }.each_pair do |name, value|
      specify "test #{name}" do
        RDF::Literal.new(value.rdf_unescape).value.should == name
      end
    end
  end
  
  describe "valid content" do
    {
      "true"  => %("true"^^<http://www.w3.org/2001/XMLSchema#boolean>),
      "false" => %("false"^^<http://www.w3.org/2001/XMLSchema#boolean>),
      "tRuE"  => %("true"^^<http://www.w3.org/2001/XMLSchema#boolean>),
      "FaLsE" => %("false"^^<http://www.w3.org/2001/XMLSchema#boolean>),
      "1"     => %("true"^^<http://www.w3.org/2001/XMLSchema#boolean>),
      "0"     => %("false"^^<http://www.w3.org/2001/XMLSchema#boolean>),
    }.each_pair do |lit, n3|
      it "should validate boolean '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.boolean).valid?.should be_true
      end

      it "should normalize boolean '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.boolean).to_s.should == n3
      end
    end

    {
      "01" => %("1"^^<http://www.w3.org/2001/XMLSchema#integer>),
      "1"  => %("1"^^<http://www.w3.org/2001/XMLSchema#integer>),
      "-1" => %("-1"^^<http://www.w3.org/2001/XMLSchema#integer>),
      "+1" => %("1"^^<http://www.w3.org/2001/XMLSchema#integer>),
    }.each_pair do |lit, n3|
      it "should validate integer '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.integer).valid?.should be_true
      end

      it "should normalize integer '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.integer).to_s.should == n3
      end
    end

    {
      "1"                              => %("1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "-1"                             => %("-1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "1."                             => %("1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "1.0"                            => %("1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "1.00"                           => %("1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "+001.00"                        => %("1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "123.456"                        => %("123.456"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "2.345"                          => %("2.345"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "1.000000000"                    => %("1.0"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "2.3"                            => %("2.3"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "2.234000005"                    => %("2.234000005"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "2.2340000000000005"             => %("2.2340000000000005"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "2.23400000000000005"            => %("2.234"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "2.23400000000000000000005"      => %("2.234"^^<http://www.w3.org/2001/XMLSchema#decimal>),
      "1.2345678901234567890123457890" => %("1.2345678901234567"^^<http://www.w3.org/2001/XMLSchema#decimal>),
    }.each_pair do |lit, n3|
      it "should validate decimal '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.decimal).valid?.should be_true
      end

      it "should normalize decimal '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.decimal).to_s.should == n3
      end
    end
    
    {
      "1"         => %("1.0E0"^^<http://www.w3.org/2001/XMLSchema#double>),
      "-1"        => %("-1.0E0"^^<http://www.w3.org/2001/XMLSchema#double>),
      "+01.000"   => %("1.0E0"^^<http://www.w3.org/2001/XMLSchema#double>),
      "1."        => %("1.0E0"^^<http://www.w3.org/2001/XMLSchema#double>),
      "1.0"       => %("1.0E0"^^<http://www.w3.org/2001/XMLSchema#double>),
      "123.456"   => %("1.23456E2"^^<http://www.w3.org/2001/XMLSchema#double>),
      "1.0e+1"    => %("1.0E1"^^<http://www.w3.org/2001/XMLSchema#double>),
      "1.0e-10"   => %("1.0E-10"^^<http://www.w3.org/2001/XMLSchema#double>),
      "123.456e4" => %("1.23456E6"^^<http://www.w3.org/2001/XMLSchema#double>),
    }.each_pair do |lit, n3|
      it "should validate double '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.double).valid?.should be_true
      end

      it "should normalize double '#{lit}'" do
        RDF::Literal.new(lit, :datatype => RDF::XSD.double).to_s.should == n3
      end
    end
  end
  
  describe "invalid content" do
    [
      RDF::Literal.new("foo", :datatype => RDF::XSD.boolean),
      RDF::Literal.new("xyz", :datatype => RDF::XSD.integer),
      RDF::Literal.new("12xyz", :datatype => RDF::XSD.integer),
      RDF::Literal.new("12.xyz", :datatype => RDF::XSD.decimal),
      RDF::Literal.new("xy.z", :datatype => RDF::XSD.double),
      RDF::Literal.new("+1.0z", :datatype => RDF::XSD.double),
    ].each do |lit|
      it "should detect invalid encoding for '#{lit.to_s}'" do
        lit.valid?.should be_false
      end
    end
  end
end
