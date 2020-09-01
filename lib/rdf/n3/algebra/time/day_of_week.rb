module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:dayOfWeek is the the day number within the week, Sunday being 0.
  class DayOfWeek < RDF::N3::Algebra::LiteralOperator
    NAME = :timeDayOfWeek

    ##
    # The time:dayOfWeek operator takes string or dateTime and returns the 0-based day of the week.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    def evaluate(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        resource = resource.as_datetime
        RDF::Literal(resource.object.strftime("%w").to_i)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
