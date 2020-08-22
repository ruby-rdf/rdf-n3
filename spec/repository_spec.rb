require_relative 'spec_helper'
require 'rdf/spec/repository'

describe RDF::N3::Repository do
  # @see lib/rdf/spec/repository.rb in rdf-spec
  it_behaves_like 'an RDF::Repository' do
    let(:repository) { RDF::N3::Repository.new }
  end

  it { is_expected.not_to be_durable }

  let(:list_subject) {RDF::Statement.new(RDF::N3::List[RDF::Literal('a'), RDF::Literal('b')], RDF::URI('p'), RDF::Literal('o'))}
  let(:list_object) {RDF::Statement.new(RDF::URI('s'), RDF::URI('p'), RDF::N3::List[RDF::Literal('a'), RDF::Literal('b')])}

  it "maintains arbitrary options" do
    repository = RDF::N3::Repository.new(foo: :bar)
    expect(repository.options).to have_key(:foo)
    expect(repository.options[:foo]).to eq :bar
  end

  describe '#query_pattern' do
    before { subject.insert(*(RDF::Spec.quads + [list_subject, list_object])) }

    it "finds a list subject constant" do
      pattern = RDF::Query::Pattern.new(list_subject.subject, nil, nil)
      solutions = []
      subject.send(:query_pattern, pattern) {|s| solutions << s}

      expect(solutions.size).to eq 1
    end
  end

  describe '#insert_to' do
    it "inserts a statement with a list subject" do
      subject << list_subject
      expect(subject.count).to eql 1
      expect(subject.statements.first).to eql list_subject
    end

    it "inserts a statement with a list object" do
      subject << list_object
      expect(subject.count).to eql 1
      expect(subject.statements.first).to eql list_object
    end
  end

  describe '#has_statement' do
    it "detects a statement with a list subject" do
      subject << list_subject
      expect(subject).to have_statement(list_subject)
    end

    it "detects a statement with a list object" do
      subject << list_object
      expect(subject).to have_statement(list_object)
    end
  end

  describe '#delete_from' do
    it "deletes a statement with a list subject" do
      subject << list_subject
      subject.delete(list_subject)
      expect(subject.count).to eql 0
    end

    it "deletes a statement with a list object" do
      subject << list_object
      subject.delete(list_object)
      expect(subject.count).to eql 0
    end
  end
end
