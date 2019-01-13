module RDF::N3::Algebra
  ##
  # The subject formula includes the object formula.
  #
  # Formula A includes formula B if there exists some substitution which when applied to B creates a formula B' such that for every statement in B' is also in A, every variable universally (or existentially) quantified in B' is quantified in the same way in A. 
  #
  # Variable substitution is applied recursively to nested compound terms such as formulae, lists and sets.
  #
  # (Understood natively by cwm when in in the antecedent of a rule. You can use this to peer inside nested formulae.)
  class LogIncludes < SPARQL::Algebra::Operator::Binary
    NAME = :logIncludes
  end
end
