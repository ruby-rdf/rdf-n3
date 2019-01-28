module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list of lists and the concatenation of all those lists is the object, then this is true.
  # @example
  #     ( (1 2) (3 4) ) list:append (1 2 3 4).
  #
  # The object can be calculated as a function of the subject.
  class Append < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :listAppend
  end
end
