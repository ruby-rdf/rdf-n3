module RDF::N3::Algebra::Log
  ##
  # The object formula is NOT a subset of subject. True iff log:includes is false. The converse of log:includes.
  # (Understood natively by cwm. The subject formula may contain variables.)
  #
  # (In cwm, variables must of course end up getting bound before the log:include test can be done, or an infinite result set would result)
  #
  # Related: See includes
  class NotIncludes < Includes
    NAME = :logNotIncludes
    URI = RDF::N3::Log.notIncludes

    ##
    # Uses log:includes and returns a solution if log:includes fails
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @option options [RDF::Query::Solutions] solutions
    #   optional initial solutions for chained queries
    # @return [RDF::Solutions] distinct solutions
    def execute(queryable, solutions:, **options)
      super
      @solutions = solutions.empty? ? RDF::Query::Solutions(RDF::Query::Solution.new) : RDF::Query::Solutions.new
    end
  end
end
