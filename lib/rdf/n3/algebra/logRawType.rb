module RDF::N3::Algebra
  ##
  # This is a low-level language type, one of log:Formula, log:Literal,  log:List, log:Set or log:Other.
  #
  # Example: log:semanticsOrError returns either a formula or a string, and you can check which using log:rawType.
  class LogRawType < SPARQL::Algebra::Operator::Binary
    NAME = :logRawType
  end
end
