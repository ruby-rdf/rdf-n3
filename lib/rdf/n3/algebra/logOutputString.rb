module RDF::N3::Algebra
  ##
  # The subject is a key and the object is a string, where the strings are to be output in the order of the keys.
  class LogOutputString < SPARQL::Algebra::Operator::Binary
    NAME = :logOutputString
  end
end
