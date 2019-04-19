module RDF::N3::Algebra::Log
  ##
  # A function to merge formulae: logical AND.
  #
  # The subject is a list of formulae. The object, which can be generated, is a formula containing a copy of each of the formulae in the list on the left. A cwm built-in function.
  class Conjunction < SPARQL::Algebra::Operator::Binary
    NAME = :logConjunction
  end
end
