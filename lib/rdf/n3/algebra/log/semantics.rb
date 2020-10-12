module RDF::N3::Algebra::Log
  ##
  # The log:semantics of a document is the formula. achieved by parsing representation of the document. For a document in Notation3, log:semantics is the log:parsedAsN3 of the log:contents of the document. For a document in RDF/XML, it is parsed according to the RDF/XML specification to yield an RDF formula (a subclass of N3 log:Formula).
  #
  # [Aside: Philosophers will be distracted here into worrying about the meaning of meaning. At least we didn't call this function "meaning"! In as much as N3 is used as an interlingua for interoperability for different systems, this for an N3 based system is the meaning  expressed by a document.]
  #
  # (Cwm knows how to go get a document and parse N3 and RDF/XML it in order to evaluate this. Other languages for web documents  may be defined whose N3 semantics are therefore also calculable, and so they could be added in due course. See for example GRDDL, RDFa, etc)
  class Semantics < RDF::N3::Algebra::ResourceOperator
    NAME = :logSemantics

    ##
    # Parses the subject into a new formula.
    #
    # Returns nil if resource does not validate, given its position
    #
    # @param [RDF::N3::List] resource
    # @return [RDF::Term]
    def evaluate(resource, position: :subject)
      case position
      when :subject
        return nil unless resource.literal? || resource.uri?
        begin
          repo = RDF::N3::Repository.new
          repo << RDF::Reader.open(resource)
          content_hash = repo.hash # used as name of resulting formula
          RDF::N3::Algebra::Formula.from_enumerable(repo, graph_name: RDF::Node.new(content_hash))
        rescue IOError, RDF::ReaderError => e
          log_error(NAME) {"error loading #{resource}: #{e}"}
          nil
        end
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
