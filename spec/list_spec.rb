# coding: utf-8
require_relative 'spec_helper'

describe RDF::N3::List do

  let(:empty) {RDF::List::NIL}
  let(:abc) {described_class[RDF::Literal.new('a'), RDF::Literal.new('b'), RDF::Literal.new('c')]}
  let(:nodes) {described_class[RDF::Node.new('a'), RDF::Node.new('b'), RDF::Node.new('c')]}
  let(:ten) {described_class[*(1..10)]}
  let(:pattern) {described_class[RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Literal("c")]}

  describe ".to_uri" do
    specify {expect(described_class.to_uri).to eq RDF::N3::List::URI}
  end

  describe "vocabulary accessors" do
    specify {expect(described_class.append).to be_a(RDF::Vocabulary::Term)}
    specify {expect(described_class.append).to eql RDF::N3::List::URI.+("append")}
  end

  describe ".try_list" do
  end

  describe "[]" do
    context "without arguments" do
      it "constructs a new empty list" do
        expect(described_class[]).to be_an(described_class)
        expect(described_class[]).to be_empty
        expect(described_class[]).to eq RDF::List::NIL
      end
    end

    context "with arguments" do
      it "constructs a new non-empty list" do
        expect(described_class[1, 2, 3]).to be_an(described_class)
        expect(described_class[1, 2, 3]).not_to be_empty
      end

      it "accepts list arguments" do
        expect { described_class[described_class[]] }.not_to raise_error
      end

      it "accepts blank node arguments" do
        expect { described_class[RDF::Node.new] }.not_to raise_error
      end

      it "accepts URI arguments" do
        expect { described_class[RDF.nil] }.not_to raise_error
      end

      it "accepts nil arguments" do
        expect { described_class[nil] }.not_to raise_error
      end

      it "accepts literal arguments" do
        expect { described_class[RDF::Literal.new("Hello, world!", language: :en)] }.not_to raise_error
      end

      it "accepts boolean arguments" do
        expect { described_class[true, false] }.not_to raise_error
      end

      it "accepts string arguments" do
        expect { described_class["foo", "bar"] }.not_to raise_error
      end

      it "accepts integer arguments" do
        expect { described_class[1, 2, 3] }.not_to raise_error
      end
    end
  end

  describe "#initialize" do
    context "with subject and graph" do
      let(:graph) {RDF::Graph.new}
      it "initializes pre-existing list" do
        n = RDF::Node.new
        graph.insert(RDF::Statement(n, RDF.first, "foo"))
        graph.insert(RDF::Statement(n, RDF.rest, RDF.nil))
        described_class.new(subject: n, graph: graph).valid?
        expect(described_class.new(subject: n, graph: graph)).to be_valid
      end
    end

    context "without subject or graph" do
    end

    context "with subject, graph and no values" do
    end

    context "with subject and values" do
    end
  end

  describe "#[]" do
    it "accepts one argument" do
      expect { empty[0] }.not_to raise_error
    end

    it "rejects fewer arguments" do
      expect { empty.__send__(:[]) }.to raise_error(ArgumentError)
    end

    it "returns a value for valid indexes" do
      expect(ten[0]).to be_a_value
    end

    it "returns nil for invalid indexes" do
      expect(empty[0]).to be_nil
      expect(ten[20]).to be_nil
    end

    context "with start index and a length" do
      it "accepts two arguments" do
        expect { ten[0, 9] }.not_to raise_error
      end

      it "returns a value" do
        expect(ten[0, 9]).to be_a_value
      end
    end

    context "with a range" do
      it "accepts one argument" do
        expect { ten[0..9] }.not_to raise_error
      end
    end
  end

  describe "#[]=" do
    it "accepts one integer argument" do
      expect { ten[0] = 0 }.not_to raise_error
    end

    it "accepts two integer arguments" do
      expect { ten[0, 0] = 0 }.not_to raise_error
    end

    it "accepts a range argument" do
      expect { ten[0..1] = 0 }.not_to raise_error
    end

    it "rejects fewer arguments" do
      expect { ten[] = 0 }.to raise_error(ArgumentError)
    end

    it "rejects extra arguments" do
      expect { ten[0, 1, 2] = 0 }.to raise_error(ArgumentError)
    end

    context "with index" do
      it "rejects string index" do
        expect { ten["1"] = 0 }.to raise_error(ArgumentError)
      end

      {
        "a[4] = '4'" => {
          initial: [],
          index: 4,
          value: "4",
          result: [nil, nil, nil, nil, "4"]
        },
        "a[-1]   = 'Z'" => {
          initial: ["A", "4"],
          index: -1,
          value: "Z",
          result: ["A", "Z"]
        },
      }.each do |name, props|
        it name do
          list = described_class[*props[:initial]]
          list[props[:index]] = props[:value]
          expect(list).to eq described_class[*props[:result]]
        end
      end
    end

    context "with start and length" do
      {
        "a[0, 3] = [ 'a', 'b', 'c' ]" => {
          initial: [nil, nil, nil, nil, "4"],
          start: 0,
          length: 3,
          value: [ 'a', 'b', 'c' ],
          result: ["a", "b", "c", nil, "4"]
        },
        "a[0, 2] = '?'" => {
          initial: ["a", 1, 2, nil, "4"],
          start: 0,
          length: 2,
          value: "?",
          result: ["?", 2, nil, "4"]
        },
        "a[0, 0] = [ 1, 2 ]" => {
          initial: ["A"],
          start: 0,
          length: 0,
          value: [ 1, 2 ],
          result: [1, 2, "A"]
        },
        "a[3, 0] = 'B'" => {
          initial: [1, 2, "A"],
          start: 3,
          length: 0,
          value: "B",
          result: [1, 2, "A", "B"]
        },
        "lorem[0, 5] = []" => {
          initial: ['lorem' 'ipsum' 'dolor' 'sit' 'amet'],
          start: 0,
          length: 5,
          value: [],
          result: []
        },
      }.each do |name, props|
        it name do
          list = described_class[*props[:initial]]
          list[props[:start], props[:length]] = props[:value]
          expect(list).to eq described_class[*props[:result]]
        end
      end

      it "sets subject to rdf:nil when list is emptied" do
        list = described_class[%(lorem ipsum dolor sit amet)]
        list[0,5] = []
        expect(list).to eq described_class[]
        expect(list.subject).to eq RDF.nil
      end
    end

    context "with range" do
      {
        "a[1..2] = [ 1, 2 ]" => {
          initial: ["a", "b", "c", nil, "4"],
          range: (1..2),
          value: [ 1, 2 ],
          result: ["a", 1, 2, nil, "4"]
        },
        "a[0..2] = 'A'" => {
          initial: ["?", 2, nil, "4"],
          range: (0..2),
          value: "A",
          result: ["A", "4"]
        },
        "a[1..-1] = nil" => {
          initial: ["A", "Z"],
          range: (1..-1),
          value: nil,
          result: ["A", nil]
        },
        "a[1..-1] = []" => {
          initial: ["A", nil],
          range: (1..-1),
          value: [],
          result: ["A"]
        },
      }.each do |name, props|
        it name do
          list = described_class[*props[:initial]]
          list[props[:range]] = props[:value]
          expect(list).to eq described_class[*props[:result]]
        end
      end
    end
  end

  describe "#<<" do
    it "accepts one argument" do
      expect { ten << 11 }.not_to raise_error
    end

    it "rejects fewer arguments" do
      expect { ten.__send__(:<<) }.to raise_error(ArgumentError)
    end

    it "appends the new value at the tail of the list" do
      ten << 11
      expect(ten.last).to eq RDF::Literal.new(11)
    end

    it "increments the length of the list by one" do
      ten << 11
      expect(ten.length).to eq 11
    end

    it "returns self" do
      expect(ten << 11).to equal(ten)
    end
  end

  describe "#shift" do
    it "returns the first element from the list" do
      expect(ten.shift).to eq RDF::Literal.new(1)
    end

    it "removes the first element from the list" do
      ten.shift
      expect(ten).to eq described_class[2, 3, 4, 5, 6, 7, 8, 9, 10]
    end

    it "should return nil from an empty list" do
      expect(empty.shift).to be_nil
    end
  end

  describe "#unshift" do
    it "adds element to beginning of list" do
      ten.unshift(0)
      expect(ten).to eq described_class[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    end

    it "should return the new list" do
      expect(ten.unshift(0)).to eq described_class[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    end
  end

  describe "#clear" do
    it "empties list" do
      expect(ten.clear).to eq described_class[]
    end
  end

  describe "#eql?" do
    it "requires an argument" do
      expect { empty.send(:eql?) }.to raise_error(ArgumentError)
    end

    it "returns true when given the same list" do
      expect(ten).to eql ten
    end

    it "returns true when comparing a list to its contents" do
      expect(ten).to eql ten.to_a
    end

    it "does not equal different list" do
      expect(abc).not_to eql ten
    end

    it "pattern matches list" do
      expect(pattern).to eql abc
    end

    it "does not match of different size" do
      expect(pattern).not_to eql ten
    end
  end

  describe "#empty?" do
    it "requires no arguments" do
      expect { empty.empty? }.not_to raise_error
    end

    it "returns a boolean" do
      expect(empty).to be_empty
      expect(abc).not_to be_empty
      expect(ten).not_to be_empty
    end
  end

  describe "#length" do
    it "requires no arguments" do
      expect { empty.length }.not_to raise_error
    end

    it "returns an integer" do
      expect(empty.length).to be_an(Integer)
    end

    it "returns the length of the list" do
      expect(empty.length).to eq 0
      expect(abc.length).to eq 3
      expect(ten.length).to eq 10
    end
  end

  describe "#size" do
    it "aliases #length" do
      expect(empty.size).to eq empty.length
      expect(ten.size).to eq ten.length
    end
  end

  describe "#index" do
    it "accepts one argument" do
      expect { ten.index(nil) }.not_to raise_error
    end
  end

  describe "#fetch" do
    it "requires one argument" do
      expect { ten.fetch }.to raise_error(ArgumentError)
      expect { ten.fetch(0) }.not_to raise_error
    end

    it "returns a value" do
      expect(ten.fetch(0)).to be_a_value
    end

    it "returns the value at the given index" do
      expect(ten.fetch(0)).to eq RDF::Literal.new(1)
      expect(ten.fetch(9)).to eq RDF::Literal.new(10)
    end

    it "raises IndexError for invalid indexes" do
      expect { ten.fetch(20) }.to raise_error(IndexError)
    end

    describe "with a default value" do
      it "accepts two arguments" do
        expect { ten.fetch(0, nil) }.not_to raise_error
      end

      it "returns the second argument for invalid indexes" do
        expect { ten.fetch(20, nil) }.not_to raise_error
        expect(ten.fetch(20, true)).to eq true
      end
    end

    describe "with a block" do
      it "yields to the given block for invalid indexes" do
        expect { ten.fetch(20) { |index| } }.not_to raise_error
        expect(ten.fetch(20) { |index| true }).to be_truthy
      end
    end
  end

  describe "#at" do
    it "accepts one argument" do
      expect { ten.at(0) }.not_to raise_error
    end
  end

  describe "#last" do
    it "requires no arguments" do
      expect { ten.last }.not_to raise_error
    end
  end

  describe "#rest" do
    it "requires no arguments" do
      expect { ten.rest }.not_to raise_error
    end
  end

  describe "#tail" do
    it "requires no arguments" do
      expect { ten.tail }.not_to raise_error
    end
  end

  describe "#each_subject" do
    describe "without a block" do
      it "requires no arguments" do
        expect { ten.each_subject }.not_to raise_error
      end

      it "returns an enumerator" do
        expect(abc.each_subject).to be_an_enumerator
      end
    end

    describe "with a block" do
      it "requires no arguments" do
        expect { ten.each_subject { |subject| } }.not_to raise_error
      end

      it "yields all subject terms in the list" do
        expect {|b| ten.each_subject(&b)}.to yield_control.exactly(10).times
      end
    end
  end

  describe "#each" do
    describe "without a block" do
      it "requires no arguments" do
        expect { ten.each }.not_to raise_error
      end

      it "returns an enumerator" do
        expect(abc.each_subject).to be_an_enumerator
      end
    end

    describe "with a block" do
      it "requires no arguments" do
        expect { ten.each { |value| } }.not_to raise_error
      end

      it "yields the correct number of times" do
        expect(abc.each.count).to eq 3
        expect(ten.each.count).to eq 10
      end
    end
  end

  describe "#each_statement" do
    describe "without a block" do
      it "requires no arguments" do
        expect { ten.each_statement }.not_to raise_error
      end

      it "returns an enumerator" do
        expect(abc.each_subject).to be_an_enumerator
      end
    end

    describe "with a block" do
      it "requires no arguments" do
        expect { ten.each_statement { |statement| } }.not_to raise_error
      end

      it "yields the correct number of times" do
        expect(abc.each_statement.count).to eq 3 * 2
        expect(ten.each_statement.count).to eq 10 * 2
      end

      it "yields statements" do
        expect {|b| ten.each_statement(&b)}.to yield_control.at_least(10).times
        ten.each_statement do |statement|
          expect(statement).to be_a_statement
        end
      end
    end

    describe "with embedded statement" do
      subject {RDF::N3::List['a', RDF::N3::List['b'], 'c']}

      it "yields the correct number of times" do
        expect(subject.each_statement.count).to eq 8
      end

      it "does not include statements with embedded lists" do
        statements = subject.each_statement.to_a
        entries = statements.select {|st| st.predicate == RDF.first}.map(&:object)
        entries.each do |e|
          expect(e).not_to be_list
        end
      end
    end
  end

  describe "#has_nodes?" do
    it "finds list with nodes" do
      expect(nodes).to have_nodes
    end

    it "rejects list with nodes" do
      expect(abc).not_to have_nodes
    end
  end

  describe "#to_existential" do
    it "creates existential vars for list having nodes" do
      expect(nodes.to_existential).to all(be_variable)
    end
  end

  describe "#variable?" do
    it "rejects list with nodes" do
      expect(nodes).not_to be_variable
    end

    it "rejects list with URIs" do
      expect(abc).not_to be_variable
    end

    it "finds list with existentials" do
      expect(nodes.to_existential).to be_variable
    end
  end

  describe "#variables" do
    it "finds no variables in constant list" do
      expect(abc.variables).to be_empty
    end

    it "finds no variables in node list" do
      expect(nodes.variables).to be_empty
    end

    it "finds variables in existential list" do
      expect(nodes.to_existential.variables).to all(be_variable)
    end
  end

  describe "#var_values" do
    it "returns an empty array with constant pattern" do
      pattern = described_class.new(values: %w(a b c))
      list = described_class.new(values: %w(a b c))
      expect(pattern.var_values(:x, list)).to be_empty
    end

    it "returns an empty array with no matching variable" do
      pattern = described_class.new(values: [RDF::Query::Variable.new(:a), RDF::Query::Variable.new(:b), RDF::Query::Variable.new(:c)])
      list = described_class.new(values: %w(a b c))
      expect(pattern.var_values(:x, list)).to be_empty
    end

    it "returns matching value" do
      pattern = described_class.new(values: [RDF::Query::Variable.new(:a), RDF::Query::Variable.new(:b), RDF::Query::Variable.new(:c)])
      list = described_class.new(values: %w(a b c))
      expect(pattern.var_values(:a, list)).to include(RDF::Literal('a'))
    end

    it "returns matching values when multiple" do
      pattern = described_class.new(values: [RDF::Query::Variable.new(:a), RDF::Query::Variable.new(:a), RDF::Query::Variable.new(:a)])
      list = described_class.new(values: %w(a b c))
      expect(pattern.var_values(:a, list)).to include(RDF::Literal('a'), RDF::Literal('b'), RDF::Literal('c'))
    end

    it "returns matching values recursively" do
      pattern = described_class.new(values: [
        RDF::Query::Variable.new(:a),
        described_class.new(values: [RDF::Query::Variable.new(:a)]),
        RDF::Query::Variable.new(:a)])
      list = described_class.new(values: ["a", described_class.new(values: ["b"]), "c"])
      expect(pattern.var_values(:a, list)).to include(RDF::Literal('a'), RDF::Literal('b'), RDF::Literal('c'))
    end
  end

  describe "#evaluate" do
    let(:constant) {RDF::N3::List[RDF::URI("A"), RDF::URI("B")]}
    let(:nodes) {described_class[RDF::Node.new('a'), RDF::Node.new('b')]}
    let(:vars) {RDF::N3::List[RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b")]}
    let(:bindings) {RDF::Query::Solution.new(a: RDF::URI("A"), b: RDF::URI("B"))}

    it "returns itself if not variable" do
      expect(constant.evaluate(bindings)).to eq constant
    end

    it "returns bound list if nodes" do
      expect(nodes.evaluate(bindings)).to eq constant
    end

    it "returns bound list if variable" do
      expect(vars.evaluate(bindings)).to eq constant
    end
  end

  describe "#solution" do
    subject {pattern.solution(abc)}

    specify("pattern[:a] #=> list[0]") { expect(subject[:a]).to eq abc[0]}
    specify("pattern[:b] #=> list[1]") { expect(subject[:b]).to eq abc[1]}
  end
end
