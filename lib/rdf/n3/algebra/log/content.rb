module RDF::N3::Algebra::Log
  ##
  # This connects a document and a string that represents it.
  #
  # (Cwm knows how to go get a document in order to evaluate this.)
  #
  # Note that the content-type of the information is not given and so must be known or guessed.
  class Content < RDF::N3::Algebra::ResourceOperator
    NAME = :logContent
    URI = RDF::N3::Log.content

    ##
    # Reads the subject into the object.
    #
    # Returns nil if resource does not validate, given its position
    #
    # @param [RDF::N3::List] resource
    # @return [RDF::Term]
    def resolve(resource, position: :subject)
      case position
      when :subject
        return nil unless resource.literal? || resource.uri?
        content = begin
          as_literal(RDF::Util::File.open_file(resource) {|f| f.read})
        rescue IOError
          nil
        end
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
