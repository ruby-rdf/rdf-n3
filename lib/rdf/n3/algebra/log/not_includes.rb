module RDF::N3::Algebra::Log
  ##
  # The object formula is NOT a subset of subject. True iff log:includes is false. The converse of log:includes.
  # (Understood natively by cwm. The subject formula may contain variables.)
  #
  # (In cwm, variables must of course end up getting bound before the log:include test can be done, or an infinite result set would result)
  #
  # Related: See includes
  class NotIncludes < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    NAME = :logNotIncludes
  end
end
