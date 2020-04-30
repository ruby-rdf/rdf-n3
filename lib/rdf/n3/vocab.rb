module RDF::N3
  # @!parse
  #   # Crypto namespace
  #   class Crypto < RDF::Vocabulary; end
  const_set("Crypto", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/crypto#")))

  # @!parse
  #   # List namespace
  #   class List < RDF::Vocabulary; end
  const_set("List", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/list#")))

  # @!parse
  #   # Log namespace
  #   class Log < RDF::Vocabulary; end
  const_set("Log", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/log#")))

  # @!parse
  #   # Math namespace
  #   class Math < RDF::Vocabulary; end
  const_set("Math", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/math#")))

  # @!parse
  #   # Rei namespace
  #   class Rei < RDF::Vocabulary; end
  const_set("Rei", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/reify#")))

  # @!parse
  #   # Str namespace
  #   class Str < RDF::Vocabulary; end
  const_set("Str", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/string#")))

  # @!parse
  #   # Time namespace
  #   class Time < RDF::Vocabulary; end
  const_set("Time", Class.new(RDF::Vocabulary("http://www.w3.org/2000/10/swap/time#")))
end
