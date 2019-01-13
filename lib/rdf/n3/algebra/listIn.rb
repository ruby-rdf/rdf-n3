module RDF::N3::Algebra
  ##
  # Any statement mentioning anything in this class is considered boring and purged by the cwm --purge option. This is a convenience, and does not have any value when published as a general fact on the web.
  class ListIn < SPARQL::Algebra::Operator::Binary
    include RDF::Util::Logger

    NAME = :listIn
  end
end
