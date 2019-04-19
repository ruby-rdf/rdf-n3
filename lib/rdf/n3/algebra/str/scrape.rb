module RDF::N3::Algebra::Str
  ##
  # The subject is a list of two strings. The second string is a regular expression in the perl, python style. It must contain one group (a part in parentheses).  If the first string in the list matches the regular expression, then the object is calculated as being thepart of the first string which matches the group.
  class Scrape < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :strScrape
  end
end
