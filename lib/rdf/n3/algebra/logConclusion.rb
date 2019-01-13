module RDF::N3::Algebra
  ##
  # All possible conclusions which can be drawn from a formula.
  #
  # The object of this function, a formula, is the set of conclusions which can be drawn from the subject formula, by successively applying any rules it contains to the data it contains. This is equivalent to cwm's "--think" command line function.  It does use built-ins, so it may for example indirectly invoke other documents, validate signatures, etc.
  class LogConclusion < SPARQL::Algebra::Operator::Binary
    NAME = :logConclusion
  end
end
