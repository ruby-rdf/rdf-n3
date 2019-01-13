$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module RDF::N3
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :Formula,          'rdf/n3/algebra/formula'

    autoload :ListAppend,       'rdf/n3/algebra/listAppend'
    autoload :ListIn,           'rdf/n3/algebra/listIn'
    autoload :ListLast,         'rdf/n3/algebra/listLast'
    autoload :ListMember,       'rdf/n3/algebra/listMember'

    autoload :LogChaff,         'rdf/n3/algebra/logChaff'
    autoload :LogConclusion,    'rdf/n3/algebra/logConclusion'
    autoload :LogConjunction,   'rdf/n3/algebra/logConjunction'
    autoload :LogEqualTo,       'rdf/n3/algebra/logEqualTo'
    autoload :LogImplies,       'rdf/n3/algebra/logImplies'
    autoload :LogIncludes,      'rdf/n3/algebra/logIncludes'
    autoload :LogNotEqualTo,    'rdf/n3/algebra/logNotEqualTo'
    autoload :LogNotIncludes,   'rdf/n3/algebra/logNotIncludes'
    autoload :LogOutputString,  'rdf/n3/algebra/logOutputString'
    autoload :LogRawType,       'rdf/n3/algebra/logRawType'

    def for(uri)
      {
        RDF::N3::List.append => ListAppend,
        RDF::N3::List.in => ListIn,
        RDF::N3::List.last => ListLast,
        RDF::N3::List.member => ListMember,

        RDF::N3::Log.chaff => LogChaff,       
        RDF::N3::Log.conclusion => LogConclusion,  
        RDF::N3::Log.conjunction => LogConjunction, 
        RDF::N3::Log.equalTo => LogEqualTo,     
        RDF::N3::Log.implies => LogImplies,     
        RDF::N3::Log.includes => LogIncludes,    
        RDF::N3::Log.notEqualTo => LogNotEqualTo,  
        RDF::N3::Log.notIncludes => LogNotIncludes, 
        RDF::N3::Log.outputString => LogOutputString,
        RDF::N3::Log.rawType => LogRawType,     
      }[uri]
    end
    module_function :for
  end
end


