module RDF::N3::Algebra::Log
  ##
  # Takes a list of a string and an IRI and creates a datatyped literal.
  class DtLit < RDF::N3::Algebra::ListOperator
    NAME = :dtlit
    URI = RDF::N3::Log.dtlit

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
        RDF::Literal(as_literal(resource.first).to_s, datatype: resource.last)
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
        elsif !list.last.uri?
          log_error(NAME) {"second component of subject must be an IRI: #{list.last.to_sxp}"}
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
