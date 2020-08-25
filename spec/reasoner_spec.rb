# coding: utf-8
require_relative 'spec_helper'
require 'rdf/trig'

describe "RDF::N3::Reasoner" do
  let(:logger) {RDF::Spec.logger}

  context "n3:log" do
    context "log:implies" do
      {
        "r1" => {
          input: %(
            @forAll :a, :b.
            ( "one"  "two" ) a :whatever.
            { (:a :b) a :whatever } log:implies { :a a :SUCCESS. :b a :SUCCESS }.
          ),
          expect: %(
            ( "one"  "two" ) a :whatever.
            "one" a :SUCCESS.
            "two" a :SUCCESS.
          )
        },
        "unify2" => {
          input: %(
            ( 17 ) a :TestCase.
            { ( ?x ) a :TestCase}  => { ?x a :RESULT }.
          ),
          expect: %(
            ( 17 ) a :TestCase.
            17 a :RESULT.
          )
        },
        "unify3" => {
          input: %(
            ( <a> ( <b> 17 <c> ) <d> ) a :TestCase.
            { ( <a> ( <b> ?x <c> ) <d> ) a :TestCase}  => { ?x a :RESULT }.
            { 17 a :RESULT } => { :THIS_TEST a :SUCCESS }.
          ),
          expect: %(
            ( <a> ( <b> 17 <c> ) <d> ) a :TestCase.
            17 a :RESULT.
            :THIS_TEST a :SUCCESS.
          )
        },
        "double" => {
          input: %(
            :dan a :Man; :home [].
            { ?WHO :home ?WHERE. ?WHERE :in ?REGION } => { ?WHO :homeRegion ?REGION }.
            { :dan :home ?WHERE} => {?WHERE :in :Texas} . 
          ),
          expect: %(
            :dan a :Man;
              :home  [:in :Texas ];
              :homeRegion :Texas .
          ),
        },
        "single_gen" => {
          input: %(
            :a :b "A noun", 3.14159265359 .
            {:a :b ?X} => { [ a :Thing ] } .
          ),
          expect: %(
            :a :b "A noun", 3.14159265359 .
            [ a :Thing] .
          )
        },
        "uses variables bound in parent" => {
          input: %(
            :a :b :c.
            ?x :b :c. # ?x bound to :a
            {:a :b :c} => {?x :d :e}.
          ),
          expect: %(
          :a :b :c; :d :e.
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          expected = parse(options[:expect])
          result = reason(options[:input])
          expect(reason(options[:input])).to be_equivalent_graph(expected, logger: logger, format: :n3)
        end
      end
    end
  end

  context "n3:list" do
    context "list:in" do
      {
        "1 in (1)": {
          input: %(
            @prefix list: <http://www.w3.org/2000/10/swap/list#>.

            { 1 list:in  (1) } => { :test4a a :SUCCESS }.
          ),
          expect: %(
            :test4a a :SUCCESS.
          )
        },
        "1 in ( 1 2 3 4 5)": {
          input: %(
            @prefix list: <http://www.w3.org/2000/10/swap/list#>.

            { 1 list:in  (  1 2 3 4 5 ) } => { :test4a a :SUCCESS }.
          ),
          expect: %(
            :test4a a :SUCCESS.
          )
        },
        "1 in ()": {
          input: %(
            @prefix list: <http://www.w3.org/2000/10/swap/list#>.

            { 1 list:in () } => { :trap1 a :FAILURE }.
          ),
          expect: %(
          )
        },
        "2 in ( 1 2 3 4 5)": {
          input: %(
            @prefix list: <http://www.w3.org/2000/10/swap/list#>.

            { 2 list:in  (  1 2 3 4 5 ) } => { :test4b a :SUCCESS }.
          ),
          expect: %(
            :test4b a :SUCCESS.
          )
        },
        "thing1 :prop1": {
          input: %(
            :thing1 :prop1 ( :test5a :test5b :test5c ) .
            { ?item list:in [ is :prop1 of :thing1 ] } => { ?item a :SUCCESS } .
          ),
          expect: %(
            :test5a a :SUCCESS.
            :test5b a :SUCCESS.
            :test5c a :SUCCESS.
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          expected = parse(options[:expect])
          expect(reason(options[:input], filter: true)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "list:append" do
      {
        "(1 2 3 4 5) (6) const": {
          input: %(
            { ((1 2 3 4 5) (6)) list:append (1 2 3 4 5 6)} => {:test1 a :success}.
          ),
          expect: %(
            :test1 a :success.
          )
        },
        "(1 2 3 4 5) (6) var": {
          input: %(
            { ((1 2 3 4 5) (6)) list:append ?item} => {:test2 :is ?item}.
          ),
          expect: %(
            :test2 :is (1 2 3 4 5 6).
          )
        },
        "() (1) const": {
          input: %(
            { (() (1)) list:append (1)} => {:test3 a :success}.
          ),
          expect: %(
            :test3 a :success.
          )
        },
        "() (1) var": {
          input: %(
            { (() (1)) list:append ?item} => {:test4 :is ?item}.
          ),
          expect: %(
            :test4 :is (1).
          )
        },
        "thing1 :prop1": {
          input: %(
            :thing1 :prop1 ( 1 2 3 ) .
            :thing2 :prop1 ( 4 ) .
            {
              ([is :prop1 of :thing1]
               [is :prop1 of :thing2]) list:append ?item
            } => {
              :test5 :is ?item
            } .
          ),
          expect: %(
            :test5 :is (1 2 3 4).
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          expected = parse(options[:expect])
          expect(reason(options[:input], filter: true)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "list:member" do
      {
        "1 in (1 2 3 4 5)": {
          input: %(
            { (  1 2 3 4 5 ) list:member 1 } => { :test4a a :SUCCESS }.
          ),
          expect: %(
            :test4a a :SUCCESS .
          )
        },
        "?x in (1 2 3 4 5)": {
          input: %(
            { (  1 2 3 4 5 ) list:member ?x } => { :test4a :is ?x }.
          ),
          expect: %(
            :test4a :is 1 .
            :test4a :is 2 .
            :test4a :is 3 .
            :test4a :is 4 .
            :test4a :is 5 .
          )
        },
        "Pythag 3 5": {
          input: %(
            {   ((3) (5))!list:member list:member ?z } => { ?z a :Pythagorean }.
          ),
          expect: %(
            3 a :Pythagorean.
            5 a :Pythagorean.
          )
        },
        #"Pythag 3 4 5 5 12 13": {
        #  input: %(
        #    {   ((3 4 5) (5 12 13))!list:member   list:member ?z } => { ?z a :Pythagorean }.
        #  ),
        #  expect: %(
        #    3 a :Pythagorean.
        #    4 a :Pythagorean.
        #    5 a :Pythagorean.
        #    12 a :Pythagorean.
        #    13 a :Pythagorean.
        #  )
        #},
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          expected = parse(options[:expect])
          expect(reason(options[:input], filter: true)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end
  end

  context "n3:string" do
    context "string:startsWith" do
      {
        "literal starts with literal" => {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            {"abc" string:startsWith "a"} => {:test a :Success}.
          ),
          expect: %(:test a :Success.)
        },
        "ext starts with literal" => {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            :abc :value "abc" .
            {[ is :value of :abc] string:startsWith "a"} => {:test a :Success}.
          ),
          expect: %(:test a :Success.)
        },
        "literal starts with ext" => {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            :a :value "a" .
            {"abc" string:startsWith [is :value of :a]} => {:test a :Success}.
          ),
          expect: %(:test a :Success.)
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          expected = parse(options[:expect])
          expect(reason(options[:input], filter: true)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end
  end

  # Parse N3 input into a repository
  def parse(input, **options)
    repo = options[:repo] || RDF::N3:: Repository.new
    RDF::N3::Reader.new(input, **options).each_statement do |statement|
      repo << statement
    end
    repo
  end

  # Reason over input, returning a repo
  def reason(input, base_uri: 'http://example.com/', filter: false, data: true, think: true, **options)
    input = parse(input, list_terms: true, **options) if input.is_a?(String)
    reasoner = RDF::N3::Reasoner.new(input, base_uri:  base_uri)
    repo = RDF::N3:: Repository.new

    reasoner.execute(logger: logger, think: think)
    if filter
      repo << reasoner.conclusions
    elsif data
      repo << reasoner.data
    else
      repo << reasoner
    end

    # Expand results with embedded lists to ease comparison
    RDF::Repository.new do |r|
      repo.each_expanded_statement do |st|
        r << st
      end
    end
  end
end
