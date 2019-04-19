$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module RDF::N3
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :Formula,                'rdf/n3/algebra/formula'

    module List
      autoload :Append,               'rdf/n3/algebra/list/append'
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
      autoload :Difference,           'rdf/n3/algebra/math/difference'
      autoload :EqualTo,              'rdf/n3/algebra/math/equalTo'
      autoload :Exponentiation,       'rdf/n3/algebra/math/exponentiation'
      autoload :GreaterThan,          'rdf/n3/algebra/math/greaterThan'
      autoload :IntegerQuotient,      'rdf/n3/algebra/math/integerQuotient'
      autoload :LessThan,             'rdf/n3/algebra/math/lessThan'
      autoload :MemberCount,          'rdf/n3/algebra/math/memberCount'
      autoload :Negation,             'rdf/n3/algebra/math/negation'
      autoload :NotEqualTo,           'rdf/n3/algebra/math/notEqualTo'
      autoload :NotGreaterThan,       'rdf/n3/algebra/math/notGreaterThan'
      autoload :NotLessThan,          'rdf/n3/algebra/math/notLessThan'
      autoload :Product,              'rdf/n3/algebra/math/product'
      autoload :Quotient,             'rdf/n3/algebra/math/quotient'
      autoload :Remainder,            'rdf/n3/algebra/math/remainder'
      autoload :Rounded,              'rdf/n3/algebra/math/rounded'
      autoload :Sum,                  'rdf/n3/algebra/math/sum'
    end

    module Str
      autoload :Concatenation,        'rdf/n3/algebra/str/concatenation'
      autoload :Contains,             'rdf/n3/algebra/str/contains'
      autoload :ContainsIgnoringCase, 'rdf/n3/algebra/str/containsIgnoringCase'
      autoload :EndsWith,             'rdf/n3/algebra/str/endsWith'
      autoload :EqualIgnoringCase,    'rdf/n3/algebra/str/equalIgnoringCase'
      autoload :Format,               'rdf/n3/algebra/str/format'
      autoload :GreaterThan,          'rdf/n3/algebra/str/greaterThan'
      autoload :LessThan,             'rdf/n3/algebra/str/lessThan'
      autoload :Matches,              'rdf/n3/algebra/str/matches'
      autoload :NotEqualIgnoringCase, 'rdf/n3/algebra/str/notEqualIgnoringCase'
      autoload :NotGreaterThan,       'rdf/n3/algebra/str/notGreaterThan'
      autoload :NotLessThan,          'rdf/n3/algebra/str/notLessThan'
      autoload :NotMatches,           'rdf/n3/algebra/str/notMatches'
      autoload :Replace,              'rdf/n3/algebra/str/replace'
      autoload :Scrape,               'rdf/n3/algebra/str/scrape'
      autoload :StartsWith,           'rdf/n3/algebra/str/startsWith'
    end

    def for(uri)
      {
        RDF::N3::List.append              => List::Append,
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

        RDF::N3::Math.absoluteValue       => Math::AbsoluteValue,
        RDF::N3::Math.difference          => Math::Difference,
        RDF::N3::Math.equalTo             => Math::EqualTo,
        RDF::N3::Math.exponentiation      => Math::Exponentiation,
        RDF::N3::Math.greaterThan         => Math::GreaterThan,
        RDF::N3::Math.integerQuotient     => Math::IntegerQuotient,
        RDF::N3::Math.lessThan            => Math::LessThan,
        RDF::N3::Math.memberCount         => Math::MemberCount,
        RDF::N3::Math.negation            => Math::Negation,
        RDF::N3::Math.notEqualTo          => Math::NotEqualTo,
        RDF::N3::Math.notGreaterThan      => Math::NotGreaterThan,
        RDF::N3::Math.notLessThan         => Math::NotLessThan,
        RDF::N3::Math.product             => Math::Product,
        RDF::N3::Math.quotient            => Math::Quotient,
        RDF::N3::Math.remainder           => Math::Remainder,
        RDF::N3::Math.rounded             => Math::Rounded,
        RDF::N3::Math.sum                 => Math::Sum,

        RDF::N3::Str.concatenation        => Str::Concatenation,
        RDF::N3::Str.contains             => Str::Contains,
        RDF::N3::Str.containsIgnoringCase => Str::ContainsIgnoringCase,
        RDF::N3::Str.endsWith             => Str::EndsWith,
        RDF::N3::Str.equalIgnoringCase    => Str::EqualIgnoringCase,
        RDF::N3::Str.format               => Str::Format,
        RDF::N3::Str.greaterThan          => Str::GreaterThan,
        RDF::N3::Str.lessThan             => Str::LessThan,
        RDF::N3::Str.matches              => Str::Matches,
        RDF::N3::Str.notEqualIgnoringCase => Str::NotEqualIgnoringCase,
        RDF::N3::Str.notGreaterThan       => Str::NotGreaterThan,
        RDF::N3::Str.notLessThan          => Str::NotLessThan,
        RDF::N3::Str.notMatches           => Str::NotMatches,
        RDF::N3::Str.replace              => Str::Replace,
        RDF::N3::Str.scrape               => Str::Scrape,
        RDF::N3::Str.startsWith           => Str::StartsWith,
      }[uri]
    end
    module_function :for
  end
end


