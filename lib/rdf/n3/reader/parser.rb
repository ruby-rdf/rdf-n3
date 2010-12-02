
module RDF::N3
  module Parser
    START = 'http://www.w3.org/2000/10/swap/grammar/n3#document'
    R_WHITESPACE = Regexp.compile('[ \t\r\n]*(?:(?:#[^\n]*)?\r?(?:$|\n))?', Regexp::MULTILINE)
    SINGLE_CHARACTER_SELECTORS = %{\t\r\n !\"#$\%&'()*.,+/;<=>?[\\]^`{|}~}
    NOT_QNAME_CHARS = SINGLE_CHARACTER_SELECTORS + "@"
    NOT_NAME_CHARS = NOT_QNAME_CHARS + ":"
    
    def parse(prod)
      todo_stack = [{:prod => prod, :terms => nil}]
      while !todo_stack.empty?
        pushed = false
        if todo_stack.last[:terms].nil?
          todo_stack.last[:terms] = []
          tok = self.token
          #puts "parse tok: #{tok}, prod #{todo_stack.last[:prod]}"
          
          # Got an opened production
          onStart(abbr(todo_stack.last[:prod]))
          return nil if tok.nil?
          
          prod_branch = @branches[todo_stack.last[:prod]]
          raise RDF::ReaderError, "No branches found for '#{todo_stack.last[:prod]}'" if prod_branch.nil?
          sequence = prod_branch[tok]
          if sequence.nil?
             dump_stack(todo_stack)
            raise RDF::ReaderError, "Found '#{tok}' when expecting a #{todo_stack.last[:prod]}. keys='#{prod_branch.keys.to_sentence}'"
          end
          todo_stack.last[:terms] += sequence
        end
        
        #puts "parse: #{todo_stack.last.inspect}"
        while !todo_stack.last[:terms].to_a.empty?
          term = todo_stack.last[:terms].shift
          if term.is_a?(String)
            puts "parse term(string): #{term}" if $verbose
            j = @pos + term.length
            word = @data[@pos, term.length]
            if word == term
              onToken(term, word)
              @pos = j
            elsif '@' + word.chop == term # FIXME: Huh? don't get this
              onToken(term, word.chop)
              @pos += j - 1
            else
              raise RDF::ReaderError, "Found '#{@data[@pos, 10]}...'; #{term} expected"
            end
          elsif regexp = @regexps[term]
            md = regexp.match(@data, @pos)
            raise RDF::ReaderError, "Token '#{@data[@pos, 10]}...' should match #{regexp}" unless md
            puts "parse term(regexp): #{term}, #{regexp}.match('#{@data[@pos, 10]}...') => '#{md.inspect}'" if $verbose
            onToken(abbr(term), md.to_s)
            @pos = md.end(0)
          else
            puts "parse term(push): #{term}" if $verbose
            todo_stack << {:prod => term, :terms => nil}
            pushed = true
            break
          end
          puts "parse: next token" if $verbose
          self.token
        end
        
        while !pushed && todo_stack.last[:terms].to_a.empty?
          #puts "parse: pop"
          todo_stack.pop
          self.onFinish
        end
      end
    end

    # Memoizer for get_token
    def token
      unless @memo.has_key?(@pos)
        result = self.get_token
        @memo[@pos] = result # Note, @pos may be updated as side-effect of get_token
      end
      puts "token: '#{@memo[@pos]}'('#{@data[@pos, 10]}...')" if $verbose
      @memo[@pos]
    end
    
    def get_token
      whitespace
      
      return nil if @pos == @data.length
      
      ch2 = @data[@pos, 2]
      return ch2 if %w(=> <= ^^).include?(ch2)
      
      ch = @data[@pos]
      @keyword_mode = false if ch == '.' && @keyword_mode
      
      return ch if SINGLE_CHARACTER_SELECTORS.include?(ch)
      return "0" if "+-0123456789".include?(ch)
      
      j = 1
      if ch == '@'
        return '@' if @pos > 0 && @data[@pos-1] == '"'

        j += 1 until NOT_NAME_CHARS.include?(@data[@pos+1+j]) # FIXME: EOF
        name = @data[(@pos+1), j]
        if name == 'keywords'
          @keywords = []
          @keyword_mode = true
        end
        return '@' + name
      end

      j += 1 until NOT_QNAME_CHARS.include?(@data[@pos+j]) # FIXME: EOF
      word = @data[(@pos+1), j]
      raise RDF::ReaderError, "Tokenizer expected qname, found #{@data[@pos, 10]}" unless word
      if @keyword_mode
        @keywords << word
      elsif @keywords.include?(word)
        if word == 'keywords'
          @keywords = []
          @keyword_mode = true
        end
        return '@' + word.to_s # implicit keyword
      end
      
      'a'
    end
    
    def whitespace
      while md = R_WHITESPACE.match(@data, @pos)
        return unless md[0].length > 0
        @pos = md.end(0)
        #puts "ws: '#{md[0]}', pos=#{@pos}"
      end
    end
    
    def abbr(prodURI)
      prodURI.to_s.split('#').last
    end
    
    def onStart(prod)
      puts ' ' * @productions.length + prod
      @productions << prod
    end

    def onFinish
      prod = @productions.pop()
      puts ' ' * @productions.length + '/' + prod
    end

    def onToken(prod, tok)
      puts ' ' * @productions.length + "#{prod}(#{tok})"
    end
    
    def dump_stack(stack)
      puts "\nstack trace:"
      stack.reverse.each do |se|
        puts "#{se[:prod]}"
        puts "  " + case se[:terms]
        when nil then "nil"
        when [] then "empty"
        else          se[:terms].join(",\n  ")
        end
      end
    end
    
    def test(input, branches, regexps)
      # FIXME: for now, read in entire doc, eventually, process as stream
      @data = input.respond_to?(:read) ? (input.rewind; input.read) : input
      #@data.force_encoding(encoding) if @data.respond_to?(:force_encoding) # for Ruby 1.9+
      @pos = 0
      
      @memo = {}
      @keyword_mode = false
      @keywords = %w(a is of this has)
      @productions = []

      @branches = branches
      @regexps = regexps
      parse(START.to_sym)
    end
  end
end