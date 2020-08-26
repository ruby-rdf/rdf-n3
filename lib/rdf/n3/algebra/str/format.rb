module RDF::N3::Algebra::Str
  class Format < RDF::N3::Algebra::ListOperator
    NAME = :strFormat

    ##
    # The subject is a list, whose first member is a format string, and whose remaining members are arguments to the format string. The formating string is in the style of python's % operator, very similar to C's sprintf(). The object is calculated from the subject.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def evaluate(list)
      format, *args = list.to_a.map(&:value)
      str = format % args
    end
  end
end
