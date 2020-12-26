module RDF::N3::Algebra::Log
  ##
  # The subject is a key and the object is a string, where the strings are to be output in the order of the keys.
  class OutputString < RDF::N3::Algebra::ResourceOperator
    NAME = :logOutputString
    URI = RDF::N3::Log.outputString

    ##
    # Resolves inputs as strings.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      SPARQL::Algebra::Expression.cast(RDF::XSD.string, resource) if resource.term?
    end

    ##
    # Returns `term2`, but adds `term2` as an output keyed on `term1`.
    #
    # @param  [RDF::Term] term1
    #   an RDF term
    # @param  [RDF::Term] term2
    #   an RDF term
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if either operand is not an RDF term or operands are not comperable
    #
    # @see RDF::Term#==
    def apply(term1, term2)
      (@options[:strings][term1.to_s] ||= []) << term2.to_s
      term2
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end
  end
end
