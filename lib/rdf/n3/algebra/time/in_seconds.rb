module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:inSeconds is the (string represntation of) the floating point number of seconds since the beginning of the era on the given system.
  class InSeconds < RDF::N3::Algebra::LiteralOperator
    NAME = :timeInSeconds

    ##
    # The time:inseconds operator takes may have either a bound subject or object.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        case resource
        when RDF::Query::Variable
          resource
        when RDF::Literal
          resource = resource.as_datetime
          # Subject evaluates to seconds from the epoc
          RDF::Literal::Double.new(resource.object.strftime("%s"))
        else
          nil
        end
      when :object
        case resource
        when RDF::Query::Variable
          resource
        when RDF::Literal
          resource = resource.as_number
          # Object evaluates to the DateTime representation of the seconds form the epoc
          RDF::Literal(RDF::Literal::DateTime.new(::Time.at(resource).utc.to_datetime).to_s)
        else
          nil
        end
      end
    end

    # Either subject or object must be a bound resource
    def valid?(subject, object)
      return true if subject.literal? || object.literal?
      log_error(NAME) {"subject or object are not literals: #{subject.inspect}, #{object.inspect}"}
      false
    end
  end
end
