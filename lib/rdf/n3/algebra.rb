$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module RDF::N3
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :Builtin,                'rdf/n3/algebra/builtin'
    autoload :Formula,                'rdf/n3/algebra/formula'
    autoload :ListOperator,           'rdf/n3/algebra/list_operator'
    autoload :LiteralOperator,        'rdf/n3/algebra/literal_operator'
    autoload :NotImplemented,         'rdf/n3/algebra/not_implemented'

    module List
      autoload :Append,               'rdf/n3/algebra/list/append'
      autoload :First,                'rdf/n3/algebra/list/first'
      autoload :In,                   'rdf/n3/algebra/list/in'
      autoload :Last,                 'rdf/n3/algebra/list/last'
      autoload :Length,               'rdf/n3/algebra/list/length'
      autoload :Member,               'rdf/n3/algebra/list/member'
    end

    module Log
      autoload :Conclusion,           'rdf/n3/algebra/log/conclusion'
      autoload :Conjunction,          'rdf/n3/algebra/log/conjunction'
      autoload :Content,              'rdf/n3/algebra/log/content'
      autoload :EqualTo,              'rdf/n3/algebra/log/equal_to'
      autoload :Implies,              'rdf/n3/algebra/log/implies'
      autoload :Includes,             'rdf/n3/algebra/log/includes'
      autoload :N3String,             'rdf/n3/algebra/log/n3_string'
      autoload :NotEqualTo,           'rdf/n3/algebra/log/not_equal_to'
      autoload :NotIncludes,          'rdf/n3/algebra/log/not_includes'
      autoload :OutputString,         'rdf/n3/algebra/log/output_string'
    end

    module Math
      autoload :AbsoluteValue,        'rdf/n3/algebra/math/absolute_value'
      autoload :ACos,                 'rdf/n3/algebra/math/acos'
      autoload :ASin,                 'rdf/n3/algebra/math/asin'
      autoload :ATan,                 'rdf/n3/algebra/math/atan'
      autoload :ACosH,                'rdf/n3/algebra/math/acosh'
      autoload :ASinH,                'rdf/n3/algebra/math/asinh'
      autoload :ATanH,                'rdf/n3/algebra/math/atanh'
      autoload :Ceiling,              'rdf/n3/algebra/math/ceiling'
      autoload :Cos,                  'rdf/n3/algebra/math/cos'
      autoload :CosH,                 'rdf/n3/algebra/math/cosh'
      autoload :Difference,           'rdf/n3/algebra/math/difference'
      autoload :EqualTo,              'rdf/n3/algebra/math/equal_to'
      autoload :Exponentiation,       'rdf/n3/algebra/math/exponentiation'
      autoload :Floor,                'rdf/n3/algebra/math/floor'
      autoload :GreaterThan,          'rdf/n3/algebra/math/greater_than'
      autoload :IntegerQuotient,      'rdf/n3/algebra/math/integer_quotient'
      autoload :LessThan,             'rdf/n3/algebra/math/less_than'
      autoload :Negation,             'rdf/n3/algebra/math/negation'
      autoload :NotEqualTo,           'rdf/n3/algebra/math/not_equal_to'
      autoload :NotGreaterThan,       'rdf/n3/algebra/math/not_greater_than'
      autoload :NotLessThan,          'rdf/n3/algebra/math/not_less_than'
      autoload :Product,              'rdf/n3/algebra/math/product'
      autoload :Quotient,             'rdf/n3/algebra/math/quotient'
      autoload :Remainder,            'rdf/n3/algebra/math/remainder'
      autoload :Rounded,              'rdf/n3/algebra/math/rounded'
      autoload :Sin,                  'rdf/n3/algebra/math/sin'
      autoload :SinH,                 'rdf/n3/algebra/math/sinh'
      autoload :Sum,                  'rdf/n3/algebra/math/sum'
      autoload :Tan,                  'rdf/n3/algebra/math/tan'
      autoload :TanH,                 'rdf/n3/algebra/math/tanh'
    end

    module Str
      autoload :Concatenation,        'rdf/n3/algebra/str/concatenation'
      autoload :Contains,             'rdf/n3/algebra/str/contains'
      autoload :ContainsIgnoringCase, 'rdf/n3/algebra/str/contains_ignoring_case'
      autoload :EndsWith,             'rdf/n3/algebra/str/ends_with'
      autoload :EqualIgnoringCase,    'rdf/n3/algebra/str/equal_ignoring_case'
      autoload :Format,               'rdf/n3/algebra/str/format'
      autoload :GreaterThan,          'rdf/n3/algebra/str/greater_than'
      autoload :LessThan,             'rdf/n3/algebra/str/less_than'
      autoload :Matches,              'rdf/n3/algebra/str/matches'
      autoload :NotEqualIgnoringCase, 'rdf/n3/algebra/str/not_equal_ignoring_case'
      autoload :NotGreaterThan,       'rdf/n3/algebra/str/not_greater_than'
      autoload :NotLessThan,          'rdf/n3/algebra/str/not_less_than'
      autoload :NotMatches,           'rdf/n3/algebra/str/not_matches'
      autoload :Replace,              'rdf/n3/algebra/str/replace'
      autoload :Scrape,               'rdf/n3/algebra/str/scrape'
      autoload :StartsWith,           'rdf/n3/algebra/str/starts_with'
    end

    module Time
      autoload :DayOfWeek,            'rdf/n3/algebra/time/day_of_week'
      autoload :Day,                  'rdf/n3/algebra/time/day'
      autoload :GmTime,               'rdf/n3/algebra/time/gm_time'
      autoload :Hour,                 'rdf/n3/algebra/time/hour'
      autoload :InSeconds,            'rdf/n3/algebra/time/in_seconds'
      autoload :LocalTime,            'rdf/n3/algebra/time/local_time'
      autoload :Minute,               'rdf/n3/algebra/time/minute'
      autoload :Month,                'rdf/n3/algebra/time/month'
      autoload :Second,               'rdf/n3/algebra/time/second'
      autoload :Timezone,             'rdf/n3/algebra/time/timezone'
      autoload :Year,                 'rdf/n3/algebra/time/year'
    end

    def for(uri)
      {
        RDF::N3::List.append              => List::Append,
        RDF::N3::List.first               => List::First,
        RDF::N3::List.in                  => List::In,
        RDF::N3::List.last                => List::Last,
        RDF::N3::List.length              => List::Length,
        RDF::N3::List.member              => List::Member,

        RDF::N3::Log.conclusion           => Log::Conclusion,
        RDF::N3::Log.conjunction          => Log::Conjunction,
        RDF::N3::Log.content              => Log::Content,
        RDF::N3::Log.equalTo              => Log::EqualTo,
        RDF::N3::Log.implies              => Log::Implies,
        RDF::N3::Log.includes             => Log::Includes,
        RDF::N3::Log.n3String             => Log::N3String,
        RDF::N3::Log.notEqualTo           => Log::NotEqualTo,
        RDF::N3::Log.notIncludes          => Log::NotIncludes,
        RDF::N3::Log.outputString         => Log::OutputString,
        RDF::N3::Log.supports             => NotImplemented,

        RDF::N3::Math.absoluteValue       => Math::AbsoluteValue,
        RDF::N3::Math.acos                => Math::ACos,
        RDF::N3::Math.asin                => Math::ASin,
        RDF::N3::Math.atan                => Math::ATan,
        RDF::N3::Math.acosh               => Math::ACosH,
        RDF::N3::Math.asinh               => Math::ASinH,
        RDF::N3::Math.atanh               => Math::ATanH,
        RDF::N3::Math.ceiling             => Math::Ceiling,
        RDF::N3::Math.cos                 => Math::Cos,
        RDF::N3::Math.cosh                => Math::CosH,
        RDF::N3::Math.difference          => Math::Difference,
        RDF::N3::Math.equalTo             => Math::EqualTo,
        RDF::N3::Math.exponentiation      => Math::Exponentiation,
        RDF::N3::Math.floor               => Math::Floor,
        RDF::N3::Math.greaterThan         => Math::GreaterThan,
        RDF::N3::Math.integerQuotient     => Math::IntegerQuotient,
        RDF::N3::Math.lessThan            => Math::LessThan,
        RDF::N3::Math.negation            => Math::Negation,
        RDF::N3::Math.notEqualTo          => Math::NotEqualTo,
        RDF::N3::Math.notGreaterThan      => Math::NotGreaterThan,
        RDF::N3::Math.notLessThan         => Math::NotLessThan,
        RDF::N3::Math.product             => Math::Product,
        RDF::N3::Math.quotient            => Math::Quotient,
        RDF::N3::Math.remainder           => Math::Remainder,
        RDF::N3::Math.rounded             => Math::Rounded,
        RDF::N3::Math.sin                 => Math::Sin,
        RDF::N3::Math.sinh                => Math::SinH,
        RDF::N3::Math.tan                 => Math::Tan,
        RDF::N3::Math.tanh                => Math::TanH,
        RDF::N3::Math[:sum]               => Math::Sum,

        RDF::N3::Str.concatenation        => Str::Concatenation,
        RDF::N3::Str.contains             => Str::Contains,
        RDF::N3::Str.containsIgnoringCase => Str::ContainsIgnoringCase,
        RDF::N3::Str.containsRoughly      => NotImplemented,
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

        RDF::N3::Time.dayOfWeek           => Time::DayOfWeek,
        RDF::N3::Time.day                 => Time::Day,
        RDF::N3::Time.gmTime              => Time::GmTime,
        RDF::N3::Time.hour                => Time::Hour,
        RDF::N3::Time.inSeconds           => Time::InSeconds,
        RDF::N3::Time.localTime           => Time::LocalTime,
        RDF::N3::Time.minute              => Time::Minute,
        RDF::N3::Time.month               => Time::Month,
        RDF::N3::Time.second              => Time::Second,
        RDF::N3::Time.timeZone            => Time::Timezone,
        RDF::N3::Time.year                => Time::Year,
      }[uri]
    end
    module_function :for
  end
end


