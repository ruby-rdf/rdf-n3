module RDF::N3::Algebra::Log
  ##
  # The subject is a key and the object is a string, where the strings are to be output in the order of the keys.
  class OutputString < RDF::N3::Algebra::ResourceOperator
    NAME = :logOutputString
    URI = RDF::N3::Log.outputString
  end
end
