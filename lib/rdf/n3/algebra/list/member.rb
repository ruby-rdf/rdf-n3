module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list and the obbject is in that list, then this is true.
  class Member < SPARQL::Algebra::Operator::Binary
    NAME = :listMember
  end
end
