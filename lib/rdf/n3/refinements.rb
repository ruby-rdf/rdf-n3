# Refinements on core RDF class behavior
module RDF::N3::Refinements
  refine ::RDF::Statement do
    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      [(variable? ? :pattern : :triple), subject, predicate, object, graph_name].compact
    end

    ##
    # Override `valid?` terms as subjects and resources as predicates.
    #
    # @return [Boolean]
    def valid?
      has_subject?    && subject.term? && subject.valid? &&
      has_predicate?  && predicate.resource? && predicate.valid? &&
      has_object?     && object.term? && object.valid? &&
      (has_graph?      ? (graph_name.resource? && graph_name.valid?) : true)
    end

    ##
    # @return [Boolean]
    def invalid?
      !valid?
    end

    ##
    # Default validate! implementation, overridden in concrete classes
    # @return [RDF::Value] `self`
    # @raise  [ArgumentError] if the value is invalid
    # @since  0.3.9
    def validate!
      raise ArgumentError, "#{self.inspect} is not valid" if invalid?
      self
    end
    alias_method :validate, :validate!

    ##
    # Returns an S-Expression (SXP) representation
    #
    # @return [String]
    def to_sxp
      to_sxp_bin.to_sxp
    end
  end

  refine ::RDF::Query::Solution do
    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      [:solution] + bindings.map {|k, v| Query::Variable.new(k, v).to_sxp_bin}
    end

    ##
    # Returns an S-Expression (SXP) representation
    #
    # @return [String]
    def to_sxp
      to_sxp_bin.to_sxp
    end
  end

  refine ::RDF::Query::Pattern do
    ##
    # Is this pattern composed only of valid components?
    #
    # @return [Boolean] `true` or `false`
    def valid?
      (has_subject?   ? (subject.term? || subject.variable?) && subject.valid? : true) && 
      (has_predicate? ? (predicate.resource? || predicate.variable?) && predicate.valid? : true) &&
      (has_object?    ? (object.term? || object.variable?) && object.valid? : true) &&
      (has_graph?     ? (graph_name.resource? || graph_name.variable?) && graph_name.valid? : true)
    rescue NoMethodError
      false
    end
  end
end
