module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the absolute value of the subject.
  class AbsoluteValue < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathAbsoluteValue
  end
end
