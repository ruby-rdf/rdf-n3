$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module RDF::N3
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :Formula,                'rdf/n3/algebra/formula'
    autoload :ListOperator,           'rdf/n3/algebra/list_operator'
    autoload :NotImplemented,         'rdf/n3/algebra/notImplemented'

    module List
      autoload :Append,               'rdf/n3/algebra/list/append'
      autoload :First,                'rdf/n3/algebra/list/first'
      autoload :In,                   'rdf/n3/algebra/list/in'
      autoload :Last,                 'rdf/n3/algebra/list/last'
      autoload :Member,               'rdf/n3/algebra/list/member'
    end

    module Log
      autoload :Conclusion,           'rdf/n3/algebra/log/conclusion'
      autoload :Conjunction,          'rdf/n3/algebra/log/conjunction'
      autoload :EqualTo,              'rdf/n3/algebra/log/equalTo'
      autoload :Implies,              'rdf/n3/algebra/log/implies'
      autoload :Includes,             'rdf/n3/algebra/log/includes'
      autoload :NotEqualTo,           'rdf/n3/algebra/log/notEqualTo'
      autoload :NotIncludes,          'rdf/n3/algebra/log/notIncludes'
      autoload :OutputString,         'rdf/n3/algebra/log/outputString'
    end

    module Math
      autoload :AbsoluteValue,        'rdf/n3/algebra/math/absoluteValue'
      autoload :Ceiling,              'rdf/n3/algebra/math/ceiling'
      autoload :Difference,           'rdf/n3/algebra/math/difference'
      autoload :Exponentiation,       'rdf/n3/algebra/math/exponentiation'
      autoload :Floor,                'rdf/n3/algebra/math/floor'
      autoload :IntegerQuotient,      'rdf/n3/algebra/math/integerQuotient'
      autoload :Negation,             'rdf/n3/algebra/math/negation'
      autoload :Product,              'rdf/n3/algebra/math/product'
      autoload :Quotient,             'rdf/n3/algebra/math/quotient'
      autoload :Remainder,            'rdf/n3/algebra/math/remainder'
      autoload :Rounded,              'rdf/n3/algebra/math/rounded'
      autoload :Sum,                  'rdf/n3/algebra/math/sum'
    end

    module Str
      autoload :Concatenation,        'rdf/n3/algebra/str/concatenation'
      autoload :ContainsIgnoringCase, 'rdf/n3/algebra/str/containsIgnoringCase'
      autoload :EqualIgnoringCase,    'rdf/n3/algebra/str/equalIgnoringCase'
      autoload :Format,               'rdf/n3/algebra/str/format'
      autoload :NotEqualIgnoringCase, 'rdf/n3/algebra/str/notEqualIgnoringCase'
      autoload :NotMatches,           'rdf/n3/algebra/str/notMatches'
      autoload :Replace,              'rdf/n3/algebra/str/replace'
      autoload :Scrape,               'rdf/n3/algebra/str/scrape'
    end

    def for(uri)
      {
        RDF::N3::List.append              => List::Append,
        RDF::N3::List.first               => List::First,
        RDF::N3::List.in                  => List::In,
        RDF::N3::List.last                => List::Last,
        RDF::N3::List.member              => List::Member,

        RDF::N3::Log.conclusion           => Log::Conclusion,
        RDF::N3::Log.conjunction          => Log::Conjunction,
        RDF::N3::Log.equalTo              => Log::EqualTo,
        RDF::N3::Log.implies              => Log::Implies,
        RDF::N3::Log.includes             => Log::Includes,
        RDF::N3::Log.notEqualTo           => Log::NotEqualTo,
        RDF::N3::Log.notIncludes          => Log::NotIncludes,
        RDF::N3::Log.outputString         => Log::OutputString,
        RDF::N3::Log.supports             => NotImplemented,

        RDF::N3::Math.absoluteValue       => Math::AbsoluteValue,
        RDF::N3::Math.ceiling             => Math::Ceiling,
        RDF::N3::Math.difference          => Math::Difference,
        RDF::N3::Math.equalTo             => SPARQL::Algebra::Operator::Equal,
        RDF::N3::Math.exponentiation      => Math::Exponentiation,
        RDF::N3::Math.floor               => Math::Floor,
        RDF::N3::Math.greaterThan         => SPARQL::Algebra::Operator::GreaterThan,
        RDF::N3::Math.integerQuotient     => Math::IntegerQuotient,
        RDF::N3::Math.lessThan            => SPARQL::Algebra::Operator::LessThan,
        RDF::N3::Math.negation            => Math::Negation,
        RDF::N3::Math.notEqualTo          => SPARQL::Algebra::Operator::NotEqual,
        RDF::N3::Math.notGreaterThan      => SPARQL::Algebra::Operator::LessThanOrEqual,
        RDF::N3::Math.notLessThan         => SPARQL::Algebra::Operator::GreaterThanOrEqual,
        RDF::N3::Math.product             => Math::Product,
        RDF::N3::Math.quotient            => Math::Quotient,
        RDF::N3::Math.remainder           => Math::Remainder,
        RDF::N3::Math.rounded             => Math::Rounded,
        RDF::N3::Math[:sum]               => Math::Sum,

        RDF::N3::Str.concatenation        => Str::Concatenation,
        RDF::N3::Str.contains             => SPARQL::Algebra::Operator::Contains,
        RDF::N3::Str.containsIgnoringCase => Str::ContainsIgnoringCase,
        RDF::N3::Str.containsRoughly      => NotImplemented,
        RDF::N3::Str.endsWith             => SPARQL::Algebra::Operator::StrEnds,
        RDF::N3::Str.equalIgnoringCase    => Str::EqualIgnoringCase,
        RDF::N3::Str.format               => Str::Format,
        RDF::N3::Str.greaterThan          => SPARQL::Algebra::Operator::GreaterThan,
        RDF::N3::Str.lessThan             => SPARQL::Algebra::Operator::LessThan,
        RDF::N3::Str.matches              => SPARQL::Algebra::Operator::Regex,
        RDF::N3::Str.notEqualIgnoringCase => Str::NotEqualIgnoringCase,
        RDF::N3::Str.notGreaterThan       => SPARQL::Algebra::Operator::LessThanOrEqual,
        RDF::N3::Str.notLessThan          => SPARQL::Algebra::Operator::GreaterThanOrEqual,
        RDF::N3::Str.notMatches           => Str::NotMatches,
        RDF::N3::Str.replace              => Str::Replace,
        RDF::N3::Str.scrape               => Str::Scrape,
        RDF::N3::Str.startsWith           => SPARQL::Algebra::Operator::StrStarts,
      }[uri]
    end
    module_function :for
  end
end


