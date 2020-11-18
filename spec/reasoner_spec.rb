# coding: utf-8
require_relative 'spec_helper'
require 'rdf/trig'

describe "RDF::N3::Reasoner" do
  let(:logger) {RDF::Spec.logger}
  before {logger.level = Logger::INFO}

  context "variables" do
    context "universals" do
      # Universal variables remain in-scope between formulae
    end

    context "existentials" do
      # Universal variables go out of scope between formulae
    end
  end

  context "n3:log" do
    context "log:conclusion" do
      {
        "conclusion-super-simple" => {
          input: %(
            {
              {
                {<a> <b> <c>} => {<test> a <SUCCESS> } .
                <a> <b> <c>.
              } log:conclusion ?y
            } => { ?y a :TestResult }.
          ),
          expect: %(
            {
              {
                {<a> <b> <c>} => {<test> a <SUCCESS> } .
                <a> <b> <c>.
              } log:conclusion ?y
            } => { ?y a :TestResult }.

            {
              <a> <b> <c> .
              <test> a <SUCCESS> .
              {<a> <b> <c> .} => {<test> a <SUCCESS> .} .
            } a :TestResult .
          )
        },
        "conclusion-simple" => {
          input: %(
            {
              {<a> <b> <c>} => {<test> a <SUCCESS> } .
              <a> <b> <c>.
            } a :TestRule.
        
            { ?x a :TestRule; log:conclusion ?y } => { ?y a :TestResult }.
          ),
          expect: %(
            {
              {<a> <b> <c>} => {<test> a <SUCCESS> } .
              <a> <b> <c>.
            } a :TestRule.
        
            { ?x a :TestRule; log:conclusion ?y } => { ?y a :TestResult }.

            {
              <a> <b> <c> .
              <test> a <SUCCESS> .
              {<a> <b> <c> .} => {<test> a <SUCCESS> .} .
            } a :TestResult .
          )
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          options = {data: false, conclusions: false}.merge(options)
          pending(options[:pending]) if options[:pending]
          expected = parse(options[:expect])
          result = reason(options[:input], **options)
          expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
        end
      end
    end

    context "log:conjunction" do
      {
        "conjunction" => {
          input: %(
            {
              ({:sky :color :blue} {:sky :color :green})
                log:conjunction ?F
            } => { ?F a :result} .
          ),
          expect: %(
            {:sky :color :blue, :green } a :result .
          )
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {data: false, conclusions: true}.merge(options)
          expected = parse(options[:expect])
          result = reason(options[:input], **options)
          expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
        end
      end
    end

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
          pending(options[:pending]) if options[:pending]
          expected = parse(options[:expect])
          result = reason(options[:input])
          expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
        end
      end
    end

    context "log:includes" do
      {
        "t1" => {
          input: %(
            {{ :a :b :c } log:includes { :a :b :c }} => { :test1 a :success } .
          ),
          expect: %(
            :test1 a :success .
          )
        },
        "t2" => {
          input: %(
            { { <#theSky> <#is> <#blue> } log:includes {<#theSky> <#is> <#blue>} } => { :test3 a :success } .
            { { <#theSky> <#is> <#blue> } log:notIncludes {<#theSky> <#is> <#blue>} } => { :test3_bis a :FAILURE } .
          ),
          expect: %(
            :test3 a :success .
          )
        },
        "quantifiers-limited-a1" => {
          input: %(
            {{ :foo :bar :baz } log:includes { :foo :bar :baz }}
            => { :testa1 a :success } .
          ),
          expect: %(
            :testa1 a :success .
          )
        },
        #"quantifiers-limited-a2" => {
        #  input: %(
        #    {{ :foo :bar :baz } log:includes { @forSome :foo. :foo :bar :baz }}
        #    => { :testa2 a :success } .
        #  ),
        #  expect: %(
        #    :testa2 a :success .
        #  ),
        #  pending: "Variable substitution"
        #},
        #"quantifiers-limited-b2" => {
        #  input: %(
        #    {{ @forSome :foo. :foo :bar :baz } log:includes {@forSome :foo. :foo :bar :baz }}
        #    => { :testb2 a :success } .
        #  ),
        #  expect: %(
        #    :testb2 a :success .
        #  ),
        #  pending: "Variable substitution"
        #},
        #"quantifiers-limited-a1d" => {
        #  input: %(
        #    {{ :fee :bar :baz } log:includes { :foo :bar :baz }}
        #    => { :testa1d a :FAILURE } .
        #  ),
        #  expect: %()
        #},
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          expected = parse(options[:expect])
          result = reason(options[:input])
          expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
        end
      end
    end

    context "log:parsedAsN3" do
      {
        "i18n" => {
          input: %(
            {":㐭 :b :c." log:parsedAsN3 ?x} => {?x a log:Formula} .
          ),
          expect: %(
            {<http://example.com/㐭> <http://example.com/b> <http://example.com/c>} a log:Formula .
          )
        },
        "log_parsedAsN3" => {
          input: %(
            @prefix log: <http://www.w3.org/2000/10/swap/log#>.
            @prefix : <#>.

            @forAll :F.

            {"""     @prefix : <http://www.w3.org/2000/10/swap/test/crypto/acc.n3#> .
                 @prefix crypto: <http://www.w3.org/2000/10/swap/crypto#> .
                 @prefix log: <http://www.w3.org/2000/10/swap/log#> .
                 @prefix os: <http://www.w3.org/2000/10/swap/os#> .
                 @prefix string: <http://www.w3.org/2000/10/swap/string#> .

                :foo     :credential <access-tina-cert.n3>;
                     :forDocument <http://www.w3.org/Member>;
                     :junk "32746213462187364732164732164321" .
            """ log:parsedAsN3 :F} log:implies { :F a :result }.
          ),
          expect: %(
            @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
            @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

            {
              <http://www.w3.org/2000/10/swap/test/crypto/acc.n3#foo> <http://www.w3.org/2000/10/swap/test/crypto/acc.n3#credential> <http://example.com/access-tina-cert.n3>;
                <http://www.w3.org/2000/10/swap/test/crypto/acc.n3#forDocument> <http://www.w3.org/Member>;
                <http://www.w3.org/2000/10/swap/test/crypto/acc.n3#junk> "32746213462187364732164732164321" .
            } a <http://example.com/#result> .
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {data: false, conclusions: true, base_uri: 'http://example.com/'}.merge(options)
          expected = parse(options[:expect])
          result = reason(options[:input], **options)
          expect(result).to be_equivalent_graph(expected, logger: logger, format: :n3)
        end
      end
    end

    context "log:n3String" do
      {
        "i18n" => {
          input: %(
            {{:㐭 :b :c} log:n3String ?x} => {?x a :interesting}.
          ),
          regexp: [
            %r("""\s*<#㐭> <#b> <#c> \.\s*""" a <#interesting> \.)m
          ]
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          result = reason(options[:input])
          n3str = RDF::N3::Writer.buffer {|writer| writer << result}

          logger.info "result: #{n3str}"
          Array(options[:regexp]).each do |re|
            logger.info "match: #{re.inspect}"
            expect(n3str).to match_re(re, logger: logger, input: n3str), logger.to_s
          end
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
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
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
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
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
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end
  end

  context "n3:math" do
    context "math:absoluteValue" do
      {
        '"1"': {
          input: %(
            { "1" math:absoluteValue 1 } => {:test1a a :SUCCESS}.
          ),
          expect: %(
            :test1a a :SUCCESS .
          )
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          if options[:exception]
            expect {reason(options[:input], **options)}.to raise_error options[:exception]
          else
            expected = parse(options[:expect])
            expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
          end
        end
      end
    end

    context "math:ceiling" do
      {
        '"2.6"': {
          input: %(
            { "2.6" math:ceiling ?x} => { ?x :valueOf "ceiling(2.7)" } .
          ),
          expect: %(
            3 :valueOf "ceiling(2.7)" .
          )
        },
        "-8.1": {
          input: %(
            { -8.1 math:ceiling ?x } => {:test2a :is ?x}.
          ),
          expect: %(
            :test2a :is -8 .
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "math:difference" do
      {
        '("8" "3")': {
          input: %(
            { ("8" "3") math:difference ?x} => { ?x :valueOf "8 - 3" } .
          ),
          expect: %(
            5 :valueOf "8 - 3" .
          )
        },
        '("8")': {
          input: %(
            { ("8") math:difference ?x } => { ?x :valueOf "8 - (error?)" } .
          ),
          expect: %()
        },
        '(8 3)': {
          input: %(
            { (8 3) math:difference ?x} => { ?x :valueOf "8 - 3" } .
          ),
          expect: %(
            5 :valueOf "8 - 3" .
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "math:floor" do
      {
        '"2.6"': {
          input: %(
            { "2.6" math:floor ?x} => { ?x :valueOf "floor(2.7)" } .
          ),
          expect: %(
            2 :valueOf "floor(2.7)" .
          )
        },
        '-8.1': {
          input: %(
            { -8.1 math:floor ?x } => {:test2a :is ?x}.
          ),
          expect: %(
            :test2a :is -9 .
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "math:greaterThan" do
      {
        '"008" > "70"': {
          input: %(
            { "008" math:greaterThan "70" } => { :test10 a :FAILURE }.
          ),
          expect: %()
        },
        '"070" > "008"': {
          input: %(
            { "70" math:greaterThan "008" } => { :test10 a :success }.
          ),
          expect: %(
            :test10 a :success .
          )
        }
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "math:product" do
      {
        '("5" "3" "2")': {
          input: %(
            { ("5" "3" "2") math:product ?x} => { ?x :valueOf "5 * 3 * 2" } .
          ),
          expect: %(
            30 :valueOf "5 * 3 * 2" .
          )
        },
        '(5 3 2)': {
          input: %(
            { (5 3 2) math:product ?x} => { ?x :valueOf "5 * 3 * 2" } .
          ),
          expect: %(
            30 :valueOf "5 * 3 * 2" .
          )
        },
        "()": {
          input: %(
            { () math:product ?x } =>  { ?x :valuOf " () math:product ?x  --- should be 1" }.
          ),
          expect: %(
            1 :valuOf " () math:product ?x  --- should be 1" .
          )
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

    context "math:sum" do
      {
        '("3" "5")': {
          input: %(
            { ("3" "5") math:sum ?x } => { ?x :valueOf "3 + 5" } .
          ),
          expect: %(
            8 :valueOf "3 + 5" .
          )
        },
        '(3 5 100)': {
          input: %(
            { (3 5 100) math:sum ?x } => { ?x :valueOf "3 + 5 + 100" } .
          ),
          expect: %(
            108 :valueOf "3 + 5 + 100" .
          )
        },
        "()": {
          input: %(
            { () math:sum ?x } =>  { ?x :valuOf " () math:sum ?x  --- should be 0" }.
          ),
          expect: %(
            0 :valuOf " () math:sum ?x  --- should be 0" .
          )
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end

      context "trig" do
        {
          "0": {
            sin: "0.0e0",
            sinh: "0.0e0",
            cos: "1.0e0",
            cosh: "1.0e0",
            tan: "0.0e0",
            tanh: "0.0e0",
          },
          "3.14159265358979323846": {
            cos: "-1.0e0"
          },
          # pi/4
          "0.7853981633974483": {
            tan: ["1.0e0", "0.9e0"],
          },
          # pi/3
          "1.0471975511965976": {
            cos: ["0.51e0", "0.49e0"],
          },
        }.each do |subject, params|
          params.each do |fun, object|
            it "#{subject} math:#{fun} #{object}" do
              if object.is_a?(Array)
                input = %({ #{subject} math:#{fun} _:x . _:x math:lessThan #{object.first}; math:greaterThan #{object.last} } => { :#{fun} a :SUCCESS} .)
                expect = %(:#{fun} a :SUCCESS .)
              else
                input = %({ #{subject} math:#{fun} ?x } => { #{subject} :#{fun} ?x} .)
                expect = %(#{subject} :#{fun} #{object} .)
              end
              logger.info "input: #{input}"
              expected = parse(expect)
              expect(reason(input, conclusions: true)).to be_equivalent_graph(expected, logger: logger)
            end
          end
        end
      end
    end

    context "math-test" do
      {
        "A nested rule": {
          input: %(
          { ?x is math:sum of (3 (8 3)!math:difference ) } 
             => { ?x :valueOf "3 + (8 - 3)" } .
          ),
          expect: %(
            8 :valueOf "3 + (8 - 3)" .
          )
        },
        "Big test": {
          input: %(
            { (	("7" "2")!math:quotient  
               	(("7" "2")!math:remainder  "10000000")!math:exponentiation
               	("a" "b" "c" "d" "e")!list:length
              ) math:sum ?x } => 
            { ?x :valueOf "(7 / 2) + ((7 % 2)^10000000) + 5 [should be 9.5]" } .
          ),
          expect: %(
            9.5 :valueOf "(7 / 2) + ((7 % 2)^10000000) + 5 [should be 9.5]" .
          )
        },
        "Combinatorial test - concatenation": {
          input: %(
          @prefix string: <http://www.w3.org/2000/10/swap/string#> .
          "3.1415926" a :testValue.
          3.1415926 a :testValue.
          "1729" a :testValue.
          1729 a :testValue.
          "0" a :testValue.
          0 a :testValue.
          { ?x a :testValue. ?y a :testValue.
            (?x ?y) math:sum ?z.
            (?x " + " ?y " = " ?z ) string:concatenation ?s
          } => { ?s a :RESULT }.
          ),
          expect: %(
            "0 + 0 = 0"     a :RESULT .
            "0 + 1729 = 1729"     a :RESULT .
            "0 + 3.1415926 = 3.1415926"     a :RESULT .
            "1729 + 0 = 1729"     a :RESULT .
            "1729 + 1729 = 3458"     a :RESULT .
            "1729 + 3.1415926 = 1732.1415926"     a :RESULT .
            "3.1415926 + 0 = 3.1415926"     a :RESULT .
            "3.1415926 + 1729 = 1732.1415926"     a :RESULT .
            "3.1415926 + 3.1415926 = 6.2831852"     a :RESULT .
          )
        },
        "Combinatorial test - worksWith": {
          input: %(
            "3.1415926" a :testValue.
            3.1415926 a :testValue.
            "1729" a :testValue.
            1729 a :testValue.
            "0" a :testValue.
            0 a :testValue.
            { ?x a :testValue. ?y a :testValue.
              ?z is math:sum of (?x (?y ?x)!math:difference).
              ?z math:equalTo ?y } => {?x :worksWith ?y}.
          ),
          expect: %(
            0 a :testValue;
              :worksWith "1729",
                1729,
                0,
                "3.1415926",
                "0",
                3.1415926 .

            "0" a :testValue;
              :worksWith "1729",
                1729,
                0,
                "3.1415926",
                "0",
                3.1415926 .

            "3.1415926" a :testValue;
              :worksWith "1729",
                1729,
                0,
                "3.1415926",
                "0",
                3.1415926 .

            3.1415926 a :testValue;
              :worksWith "1729",
                1729,
                0,
                "3.1415926",
                "0",
                3.1415926 .

            1729 a :testValue;
              :worksWith "1729",
                1729,
                0,
                "3.1415926",
                "0",
                3.1415926 .

            "1729" a :testValue;
              :worksWith "1729",
                1729,
                0,
                "3.1415926",
                "0",
                3.1415926 .
          ),
          conclusions: false, data: true
        },
      }.each do |name, options|
        it name do
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          logger.info "input: #{options[:input]}"
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end
  end

  context "n3:string" do
    context "string:concatenation" do
      {
        "string": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            {("foo" "bar") string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "foobar" .)
        },
        "integer": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            {(1 01) string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "11" .)
        },
        "decimal": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            {(0.0 1.0 2.5 -2.5) string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "012.5-2.5" .)
        },
        "boolean": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
            {(
              true
              false
              "0"^^xsd:boolean
             ) string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "truefalsefalse" .)
        },
        "float": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
            {(
              "0E1"^^xsd:float
              "1E0"^^xsd:float
              "1.25"^^xsd:float 
              "-7.875"^^xsd:float
             ) string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "011.25-7.875" .)
        },
        "double": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            {(0E1 1E0 1.23E3) string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "011230" .)
        },
        "IRI": {
          input: %(
            @prefix string: <http://www.w3.org/2000/10/swap/string#>.
            {(:a " " :b) string:concatenation ?x} => {:test :is ?x}.
          ),
          expect: %(:test :is "http://example.org/a http://example.org/b" .),
          base_uri: "http://example.org/"
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect], base_uri: options[:base_uri])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end

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
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
        end
      end
    end
  end

  context "n3:time" do
    context "time:day" do
      {
        "2002-06-22T22:09:32-05:00" => {
          input: %(
            { "2002-06-22T22:09:32-05:00" time:day ?x } => { :test1 :is "22" }.
          ),
          expect: %(:test1 :is "22".)
        },
      }.each do |name, options|
        it name do
          logger.info "input: #{options[:input]}"
          pending(options[:pending]) if options[:pending]
          options = {conclusions: true}.merge(options)
          expected = parse(options[:expect])
          expect(reason(options[:input], **options)).to be_equivalent_graph(expected, logger: logger)
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
  def reason(input, base_uri: nil, conclusions: false, data: true, think: true, **options)
    input = parse(input, list_terms: true, base_uri: base_uri, **options) if input.is_a?(String)
    reasoner = RDF::N3::Reasoner.new(input, logger: logger, base_uri: base_uri)
    repo = RDF::N3:: Repository.new

    reasoner.execute(think: think)
    if conclusions
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
