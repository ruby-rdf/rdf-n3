module RDF::N3::Algebra::Log
  ##
  # The subject is a key and the object is a string, where the strings are to be output in the order of the keys.
  class OutputString < SPARQL::Algebra::Operator::Binary
    NAME = :logOutputString
  end
end
