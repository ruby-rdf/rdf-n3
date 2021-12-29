module RDF::N3::Algebra::Log
  ##
  # Takes a list of two strings creates a language-tagged literal.
  class LangLit < RDF::N3::Algebra::ListOperator
    NAME = :langlit
    URI = RDF::N3::Log.langlit

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
        RDF::Literal(as_literal(resource.first).to_s, language: resource.last.to_s.to_sym)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end

    def validate(list)
      if super(list)
        if list.length != 2
          log_error(NAME) {"operand is not a list with two elements: #{list.to_sxp}"}
          false
        elsif !list.last.to_s.match?(/^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/)
          log_warn(NAME) {"second component of subject should be BCP47 language tag: #{list.last.to_sxp}"}
          false
        else
          true
        end
      else
        false
      end
    end
  end
end
