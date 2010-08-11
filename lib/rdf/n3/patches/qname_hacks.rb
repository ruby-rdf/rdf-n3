module RDF
  class URI
    #unless defined?(:vocab)
      def vocab
        # Find vocabulary if not assigned
        return @vocab if @vocab
        
        Vocabulary.each do |vocab|
          return self.vocab = vocab if to_s.index(vocab.to_uri.to_s) == 0
        end
        nil
      end
    
      def vocab=(value)
        raise "Vocab #{value.inspect} is not a Vocabulary!" if value.is_a?(Array)
        @vocab = value
      end
      
      def qname
        @qname ||= if vocab
          raise "Vocab #{vocab.inspect} is not a Vocabulary!" if vocab.is_a?(Array)
          vocab_name = vocab.__name__.to_s.split('::').last.downcase
          local_name = to_s[vocab.to_uri.to_s.size..-1]
          vocab_name && local_name && [vocab_name.to_sym, local_name.empty? ? nil : local_name.to_sym]
        end
      end
    #end
  end
  
  class Vocabulary
    def self.[](property)
      @prop_uri ||= {}
      @prop_uri[property] ||= begin
        uri = RDF::URI.intern([to_s, property.to_s].join(''))
        uri.vocab = self
        uri
      end
    end

    def [](property)
      @prop_uri ||= {}
      @prop_uri[property] ||= begin
        uri = RDF::URI.intern([to_s, property.to_s].join(''))
        uri.vocab = self
        uri
      end
    end
    
    def to_uri
      @uri ||= begin
        uri = RDF::URI.intern(to_s)
        uri.vocab = self
        uri
      end
    end
  end
end