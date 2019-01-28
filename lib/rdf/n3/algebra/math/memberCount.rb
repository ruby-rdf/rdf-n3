module RDF::N3::Algebra::Math
  ##
  # The number of items in a list. The subject is a list, the object is calculated as the number of members.
  class MemberCount < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathMemberCount
  end
end
