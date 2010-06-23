module RDF
  class Literal
    ##
    # Re-define initialize/new to call _normalize_ on value.
    # @param  [Object]
    # @option options [Symbol] :language (nil)
    # @option options [URI]    :datatype (nil)
    # @option options[Hash]    :namespaces ({})
    def initialize_with_normalization(value, options = {})
      initialize_without_normalization(value, options)
      normalize(options)
    end
    
    alias_method :initialize_without_normalization, :initialize
    alias_method :initialize, :initialize_with_normalization

    def valid?
      case datatype
      when XSD.boolean   then %w(1 true 0 false).include?(value.to_s.downcase)
      when XSD.decimal   then !!value.to_s.match(/^[\+\-]?\d+(\.\d*)?$/)
      when XSD.double    then !!value.to_s.match(/^[\+\-]?\d+(\.\d*([eE][\+\-]?\d+)?)?$/)
      when XSD.integer   then !!value.to_s.match(/^[\+\-]?\d+$/)
      else                    true
      end
    end

    protected
    
    # Normalize literal value
    #
    # Options is a hash passed to initialize
    def normalize(options = {})
      return unless valid?  # Only normalize valid value
      
      case datatype
      when XSD.boolean    then %(1 true).include?(@value.to_s.downcase) ? "true" : "false"
      when XSD.integer    then @value.to_i.to_s
      when XSD.decimal    then normalize_decimal(@value, options)
      when XSD.double     then normalize_double(@value, options)
      when XSD.time       then @value.is_a?(Time) ? @value.strftime("%H:%M:%S%Z").sub(/\+00:00|UTC/, "Z") : @value.to_s
      when XSD.dateTime   then @value.is_a?(DateTime) ? @value.strftime("%Y-%m-%dT%H:%M:%S%Z").sub(/\+00:00|UTC/, "Z") : @value.to_s
      when XSD.date       then @value.is_a?(Date) ? @value.strftime("%Y-%m-%d%Z").sub(/\+00:00|UTC/, "Z") : @value.to_s
      when XSD.XMLLiteral then normalize_xml(@value, options)
      else                    @value.to_s
      end
    end
    
    def normalize_decimal(contents, options)
      # Can't use simple %f transformation do to special requirements from N3 tests in representation
      i, f = contents.to_s.split(".")
      f = f.to_s[0,16]  # Truncate after 15 decimal places
      i.sub!(/^\+?0+(\d)$/, '\1')
      f.sub!(/0*$/, '')
      f = "0" if f.empty?
      "#{i}.#{f}"
    end
    
    def normalize_double(contents, options)
      i, f, e = ("%.16E" % contents.to_f).split(/[\.E]/)
      f.sub!(/0*$/, '')
      f = "0" if f.empty?
      e.sub!(/^\+?0+(\d)$/, '\1')
      "#{i}.#{f}E#{e}"
    end
    
    # Normalize an XML Literal, by adding necessary namespaces.
    # This should be done as part of initialize
    #
    # namespaces is a hash of prefix => URIs
    def normalize_xmlliteral(contents, options = {})
      options[:namespaces] ||= {}

      begin
        # Only normalize if Nokogiri is included
        require 'nokogiri' unless defined?(Nokogiri)
      rescue LoadError => e
        contents.to_s   # No normalization
      end
      
      if contents.is_a?(String)
        ns_hash = {}
        options[:namespaces].each_pair do |prefix, uri|
          attr = prefix.to_s.empty? ? "xmlns" : "xmlns:#{prefix}"
          ns_hash[attr] = uri.to_s
        end
        ns_strs = []
        ns_hash.each_pair {|a, u| ns_strs << "#{a}=\"#{u}\""}

        # Add inherited namespaces to created root element so that they're inherited to sub-elements
        contents = Nokogiri::XML::Document.parse("<foo #{ns_strs.join(" ")}>#{contents}</foo>").root.children
      end

      # Add already mapped namespaces and language
      contents.map do |c|
        if c.is_a?(Nokogiri::XML::Element)
          c = Nokogiri::XML.parse(c.dup.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS)).root
          # Gather namespaces from self and decendant nodes
          c.traverse do |n|
            ns = n.namespace
            next unless ns
            prefix = ns.prefix ? "xmlns:#{ns.prefix}" : "xmlns"
            c[prefix] = ns.href.to_s unless c.namespaces[prefix]
          end
          
          # Add lanuage
          if options[:language] && c["lang"].to_s.empty?
            c["xml:lang"] = options[:language]
          end
        end
        c.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS)
      end.join("")
    end
  end
  
  class NormalizationError < IOError; end
end