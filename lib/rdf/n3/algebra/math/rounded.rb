module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the subject rounded to the nearest integer.
  class Rounded < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :mathRounded
  end
end
