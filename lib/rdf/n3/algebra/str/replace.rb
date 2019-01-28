module RDF::N3::Algebra::Str
  ##
  # A built-in for replacing characters or sub. takes a list of 3 strings; the first is the input data, the second the old and the third the new string. The object is calculated as the rplaced string.
  #
  # @example
  #     ("fofof bar", "of", "baz") string:replace "fbazbaz bar"
  class Replace < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strReplace
  end
end
