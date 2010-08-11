$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Writer do
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
        %r(^foaf:b foaf:c foaf:d \.$)]
      )
    end

    it "should use qname URIs with empty prefix" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . <http://xmlns.com/foaf/0.1/b> <http://xmlns.com/foaf/0.1/c> <http://xmlns.com/foaf/0.1/d> .)
      serialize(input, nil,
        [%r(^@prefix : <http://xmlns.com/foaf/0.1/> \.$),
        %r(^:b :c :d \.$)],
        :default_namespace => RDF::FOAF
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
        [%r(^\s+a :class;$),
        %r(^\s+rdfs:label "label"),
        %r(^:b dc11:title \"title\"),
        %r(^\s+:c :d)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate object list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :b :c :d, :e .)
      serialize(input, nil,
        [%r(^@prefix : <http://xmlns.com/foaf/0.1/> \.$),
        %r(^:b :c :d,$),
        %r(^\s+:e \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate property list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :b :c :d; :e :f .)
      serialize(input, nil,
        [%r(^@prefix : <http://xmlns.com/foaf/0.1/> \.$),
        %r(^:b :c :d;$),
        %r(^\s+:e :f \.$)],
        :default_namespace => RDF::FOAF
      )
    end
  end
  
  describe "anons" do
    it "should generate bare anon" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . [:a :b] .)
      serialize(input, nil,
        [%r(^\s*\[ :a :b\] \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate anon as subject" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . [:a :b] :c :d .)
      serialize(input, nil,
        [%r(^\s*\[ :a :b;$),
        %r(^\s+:c :d\] \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate anon as object" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :a :b [:c :d] .)
      serialize(input, nil,
        [%r(^\s*\:a :b \[ :c :d\] \.$)],
        :default_namespace => RDF::FOAF
      )
    end
  end
  
  describe "lists" do
    it "should generate bare list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . (:a :b) .)
      serialize(input, nil,
        [%r(^\(:a :b\) \.$)],
        :default_namespace => RDF::FOAF
      )
    end

    it "should generate literal list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :a :b ( "apple" "banana" ) .)
      serialize(input, nil,
        [%r(^:a :b \("apple" "banana"\) \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate empty list" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :a :b () .)
      serialize(input, nil,
        [%r(^:a :b \(\) \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate empty list(2)" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :emptyList = () .)
      serialize(input, nil,
        [%r(^:emptyList (<.*sameAs>|owl:sameAs) \(\) \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate empty list as subject" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . () :a :b .)
      serialize(input, nil,
        [%r(^\(\) :a :b \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate list as subject" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . (:a) :b :c .)
      serialize(input, nil,
        [%r(^\(:a\) :b :c \.$)],
        :default_namespace => RDF::FOAF
      )
    end

    it "should generate list of empties" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :listOf2Empties = (() ()) .)
      serialize(input, nil,
        [%r(^:listOf2Empties (<.*sameAs>|owl:sameAs) \(\(\) \(\)\) \.$)],
        :default_namespace => RDF::FOAF
      )
    end
    
    it "should generate list anon" do
      input = %(@prefix : <http://xmlns.com/foaf/0.1/> . :twoAnons = ([a :mother] [a :father]) .)
      serialize(input, nil,
        [%r(^:twoAnons (<.*sameAs>|owl:sameAs) \(\[\s*a :mother\] \[\s*a :father\]\) \.$)],
        :default_namespace => RDF::FOAF
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
      serialize(input, nil,
        [%r(:a rdfs:domain \[\s*a owl:Class;\s+owl:unionOf\s+\(:b\s+:c\)\]\s*\.$)m],
        :default_namespace => RDF::FOAF
      )
    end
  end
  
  # W3C Turtle Test suite from http://www.w3.org/2000/10/swap/test/regression.n3
  describe "w3c turtle tests" do
    require 'rdf_helper'

    def self.positive_tests
      RdfHelper::TestCase.test_cases(TURTLE_TEST, TURTLE_DIR)
    end

    positive_tests.each do |t|
      #puts t.inspect
      #next unless t.name == "test-04"
      
      specify "#{t.name}: " + (t.description || "#{t.inputDocument}") do
        # Skip tests for very long files, too long
        if %w(test-14 test-15 test-16 rdfq-results).include?(t.name)
          pending("Skip very long input file")
        elsif !defined?(::Encoding) && %w(test-18).include?(t.name)
          pending("Not supported in Ruby 1.8")
        elsif %w(test-29).include?(t.name)
          pending("Silly test")
        else
          begin
            t.run_test do |rdf_string|
              t.compare = :none
              serialize(rdf_string, t.about.to_s)
            end
          #rescue #Spec::Expectations::ExpectationNotMetError => e
          #  pending() {  raise }
          end
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
    g = parse(ntstr, :base_uri => base)
    @debug = []
    result = RDF::N3::Writer.buffer(options.merge(:debug => @debug, :base_uri => base)) do |writer|
      writer << g
    end
    puts result if $verbose
    
    regexps.each do |re|
      result.should match_re(re, :about => base, :trace => @debug, :inputDocument => ntstr)
    end
    
    result
  end
end