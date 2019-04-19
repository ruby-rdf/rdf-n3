module RDF::N3::Algebra::Str
  ##
  # True iff the subject string starts with the object string.
  class StartsWith < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::Enumerable
    include RDF::Util::Logger

    NAME = :strStartsWith

    ##
    # The string:startsWith operator corresponds to the XPath fn:starts-with function. The arguments must be argument compatible otherwise an error is raised.
    #
    # For constant inputs that evaulate to true, the original solutions are returned.
    #
    # For constant inputs that evaluate to false, the empty solution set is returned. XXX
    #
    # Otherwise, for variable operands, it binds matching variables to the solution set.
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Query::Solutions] solutions
    # @return [RDF::Query::Solutions]
    # @raise  [TypeError] if operands are not compatible
    def execute(queryable, solutions:, **options)
      log_debug {"strStartsWith #{operands.to_sxp}"}
      @solutions = solutions.filter do |solution|
        left, right = operands.map {|op| op.evaluate(solution.bindings)}
        if !left.compatible?(right)
          log_debug {"(strStartsWith incompatible operands #{[left, right].to_sxp})"}
          false
        elsif !left.to_s.start_with?(right.to_s)
          log_debug {"(strStartsWith false #{[left, right].to_sxp})"}
          false
        else
          log_debug {"(strStartsWith true #{[left, right].to_sxp})"}
          true
        end
      end
    end

    ##
    # Does not yield statements.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] solution
    # @yieldreturn [void] ignored
    def each(&block)
    end

    # Graph name associated with this operation, using the name of the parent
    # @return [RDF::Resource]
    def graph_name; parent.graph_name; end
  end
end
