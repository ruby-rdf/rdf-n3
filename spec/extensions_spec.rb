# coding: utf-8
require_relative 'spec_helper'

describe RDF::List do
  let(:constant) {RDF::List[RDF::URI("A"), RDF::URI("B")]}
  let(:nodes) {RDF::List[RDF::Node.new("a"), RDF::Node.new("b")]}
  let(:vars) {RDF::List[RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b")]}

  describe "#variable?" do
    context "constant" do
      subject {constant}
      specify {is_expected.not_to be_variable}
      specify {is_expected.to be_constant}
    end

    context "nodes" do
      subject {nodes}
      specify {is_expected.not_to be_variable}
      specify {is_expected.to be_constant}
    end

    context "vars" do
      subject {vars}
      specify {is_expected.to be_variable}
      specify {is_expected.not_to be_constant}
    end
  end
end

describe RDF::Value do
  describe "#formula?" do
    {
      RDF::Node.new("a") => false,
      RDF::Literal.new("a") => false,
      RDF::URI("a") => false,
      RDF::Graph.new => false,
      RDF::List[RDF::URI("a")] => false,
      RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o")) => false,
      RDF::N3::Algebra::Formula.new => true
    }.each do |term, is_formula|
      context term.class.to_s do
        if is_formula
          specify {expect(term).to be_formula}
        else
          specify {expect(term).not_to be_formula}
        end
      end
    end
  end
end

describe RDF::Term do
  describe "#sameTerm?" do
    {
      "lita lita": [RDF::Literal.new("a"), RDF::Literal.new("a"), true],
      "lita litb": [RDF::Literal.new("a"), RDF::Literal.new("b"), false],
      "lita nodea": [RDF::Literal.new("a"), RDF::Node.intern("a"), false],
      "lita uria": [RDF::Literal.new("a"), RDF::URI("a"), false],
      "lita vara": [RDF::Literal.new("a"), RDF::Query::Variable.new("a"), false],

      "nodea nodea": [RDF::Node.intern("a"), RDF::Node.intern("a"), true],
      "nodea nodeb": [RDF::Node.intern("a"), RDF::Node.intern("b"), false],

      "uria uria": [RDF::URI("a"), RDF::URI("a"), true],
      "uria urib": [RDF::URI("a"), RDF::URI("b"), false],

      "vara vara": [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("a"), true],
      "vara varb": [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), false],
    }.each do |term, (a, b, tf)|
      context term do
        if tf
          specify {expect(a).to be_sameTerm(b)}
        else
          specify {expect(a).not_to be_sameTerm(b)}
        end
      end
    end
  end
end

describe RDF::Node do
  describe "#evaluate" do
    let(:node) {RDF::Node.intern("a")}

    it "returns itself if not bound" do
      expect(node.evaluate({})).to eq node
    end
  end
end

describe RDF::Query::Pattern do
  describe "#eql?" do
    let(:stmt1) {RDF::Statement.new(RDF::N3::List[RDF::URI("a"), RDF::URI("b")], RDF::URI("p"), RDF::N3::List[RDF::URI("d"), RDF::URI("e")])}
    let(:stmt2) {RDF::Statement.new(RDF::N3::List[RDF::URI("a"), RDF::URI("b")], RDF::URI("p"), RDF::URI("o"))}
    let(:pat1) {RDF::Query::Pattern.new(RDF::N3::List[RDF::URI("a"), RDF::URI("b")], RDF::URI("p"), RDF::N3::List[RDF::URI("d"), RDF::URI("e")])}

    it "equals itself" do
      expect(pat1).to eql pat1
    end

    it "equals matching statement" do
      expect(pat1).to eql stmt1
    end

    it "does not equal non-matching statement" do
      expect(pat1).not_to eql stmt2
    end
  end
end
