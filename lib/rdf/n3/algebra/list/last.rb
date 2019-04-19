module RDF::N3::Algebra::List
  ##
  # Iff the suject is a list and the obbject is the last thing that list, then this is true.
  #
  # The object can be calculated as a function of the list.
  class Last < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :listLast
  end
end
