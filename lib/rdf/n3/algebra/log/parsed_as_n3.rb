module RDF::N3::Algebra::Log
  ##
  # The subject string, parsed as N3, gives this formula.
  class ParsedAsN3 < RDF::N3::Algebra::ResourceOperator
    NAME = :logParsedAsN3

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
        return nil unless resource.literal?
        begin
          repo = RDF::N3::Repository.new
          repo << RDF::N3::Reader.new(resource.to_s, list_terms: true, **@options)
          log_debug("logParsedAsN3") {SXP::Generator.string repo.statements.to_sxp_bin}
          content_hash = resource.hash # used as name of resulting formula
          form = RDF::N3::Algebra::Formula.from_enumerable(repo, graph_name: RDF::Node.intern(content_hash))
          log_info(NAME) {"form hash (#{resource}): #{form.hash}"}
          form
        rescue RDF::ReaderError
          nil
        end
      when :object
        return nil unless resource.literal? || resource.is_a?(RDF::Query::Variable)
        resource
      end
    end
  end
end
