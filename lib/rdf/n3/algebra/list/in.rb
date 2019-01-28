module RDF::N3::Algebra::List
  ##
  # Iff the object is a list and the subject is in that list, then this is true.
  class In < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :listIn
  end
end
