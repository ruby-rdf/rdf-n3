# coding: utf-8
# Simple parser to go through productions without attempting evaluation
module RDF::N3
  module Parser
    START = 'http://www.w3.org/2000/10/swap/grammar/n3#document'
    R_WHITESPACE = Regexp.compile('\A\s*(?:#.*$)?')
    R_MLSTRING = Regexp.compile("^.*([^\"\\\\]*)\"\"\"")
    SINGLE_CHARACTER_SELECTORS = %{\t\r\n !\"#$\%&'()*.,+/;<=>?[\\]^`{|}~}
    NOT_QNAME_CHARS = SINGLE_CHARACTER_SELECTORS + "@"
    NOT_NAME_CHARS = NOT_QNAME_CHARS + ":"
    
    def error(str)
      log_error(str, lineno: @lineno, exception: RDF::ReaderError)
    end
    
    def parse(prod)
      todo_stack = [{prod: prod, terms: nil}]
      while !todo_stack.empty?
        pushed = false
        if todo_stack.last[:terms].nil?
          todo_stack.last[:terms] = []
          tok = self.token
          #log_debug("parse tok: '#{tok}'") {"prod #{todo_stack.last[:prod]}"}
          
          # Got an opened production
          onStart(abbr(todo_stack.last[:prod]))
          break if tok.nil?
          
          cur_prod = todo_stack.last[:prod]
          prod_branch = @branches[cur_prod]
          error("No branches found for '#{abbr(cur_prod)}'") if prod_branch.nil?
          sequence = prod_branch[tok]
          if sequence.nil?
            dump_stack(todo_stack) if $verbose
            expected = prod_branch.values.uniq.map {|u| u.map {|v| abbr(v).inspect}.join(",")}
            error("Found '#{tok}' when parsing a #{abbr(cur_prod)}. expected #{expected.join(' | ')}")
          end
          #log_debug("sequence") {sequence.inspect}
          todo_stack.last[:terms] += sequence
        end
        
        #log_debug("parse") {todo_stack.last.inspect}
        while !todo_stack.last[:terms].to_a.empty?
          term = todo_stack.last[:terms].shift
          if term.is_a?(String)
            log_debug("parse term(string)") {term.to_s}
            word = buffer[0, term.length]
            if word == term
              onToken(term, word)
              consume(term.length)
            elsif '@' + word.chop == term && @keywords.include?(word.chop)
              onToken(term, word.chop)
              consume(term.length - 1)
            else
              error("Found '#{buffer[0, 10]}...'; #{term} expected")
            end
          elsif regexp = @regexps[term]
            if abbr(term) == 'string' && buffer[0, 3] == '"""'
              # Read until end of multi-line comment if this is the start of a multi-line comment
              string = '"""'
              consume(3)
              next_line = buffer
              #log_debug("ml-str(start)") {next_line.dump}
              until md = R_MLSTRING.match(next_line)
                begin
                  string += next_line
                  next_line = readline
                rescue EOFError
                  error("EOF reached searching for end of multi-line comment")
                end
              end
              string += md[0].to_s
              consume(md[0].to_s.length)
              onToken('string', string)
              #log_debug("ml-str now") {buffer.dump}
            else
              md = regexp.match(buffer)
              error("Token(#{abbr(term)}) '#{buffer[0, 10]}...' should match #{regexp}") unless md
              log_debug("parse") {"term(#{abbr(term)}:regexp): #{term}, #{regexp}.match('#{buffer[0, 10]}...') => '#{md.inspect.force_encoding(Encoding::UTF_8)}'"}
              onToken(abbr(term), md.to_s)
              consume(md[0].length)
            end
          else
            log_debug("parse term(push)") {term}
            todo_stack << {prod: term, terms: nil}
            pushed = true
            break
          end
          self.token
        end
        
        while !pushed && todo_stack.last[:terms].to_a.empty?
          todo_stack.pop
          self.onFinish
        end
      end
      while !todo_stack.empty?
        todo_stack.pop
        self.onFinish
      end
    end

    # Memoizer for get_token
    def token
      unless @memo.has_key?(@pos)
        tok = self.get_token
        @memo[@pos] = tok
        log_debug("token") {"'#{tok}'('#{buffer[0, 10]}...')"} if buffer
      end
      @memo[@pos]
    end

    def get_token
      whitespace
      
      return nil if buffer.nil?
      
      ch2 = buffer[0, 2]
      return ch2 if %w(=> <= ^^).include?(ch2)
      
      ch = buffer[0, 1]
      @keyword_mode = false if ch == '.' && @keyword_mode
      
      return ch if SINGLE_CHARACTER_SELECTORS.include?(ch)
      return ":" if ch == ":"
      return "0" if "+-0123456789".include?(ch)
      
      if ch == '@'
        return '@' if @pos > 0 && @line[@pos-1, 1] == '"'

        j = 0
        j += 1 while buffer[j+1, 1] && !NOT_NAME_CHARS.include?(buffer[j+1, 1])
        name = buffer[1, j]
        if name == 'keywords'
          @keywords = []
          @keyword_mode = true
        end
        return '@' + name
      end

      j = 0
      j += 1 while buffer[j, 1] && !NOT_QNAME_CHARS.include?(buffer[j, 1])
      word = buffer[0, j]
      error("Tokenizer expected qname, found #{buffer[0, 10]}") unless word
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
      while buffer && md = R_WHITESPACE.match(buffer)
        return unless md[0].length > 0
        consume(md[0].length)
        #log_debug("ws") {"'#{md[0]}', pos=#{@pos}"}
      end
    end
    
    def readline
      @line = @input.readline
      @lineno += 1
      @line.force_encoding(Encoding::UTF_8)
      log_debug("readline[#{@lineno}]") {@line.dump}
      @pos = 0
      @line
    rescue EOFError
      @line, @pos = nil, 0
    end
    
    # Return data from current off set to end of line
    def buffer
      @line[@pos, @line.length - @pos] unless @line.nil?
    end
    
    # Cause n characters of line to be consumed. Read new line while line is empty or until eof
    def consume(n)
      @memo = {}
      @pos += n
      readline while @line && @line.length <= @pos
      #log_debug("consume[#{n}]") {buffer}
    end
    
    def abbr(prodURI)
      prodURI.to_s.split('#').last
    end
    
    def onStart(prod)
      $stdout.puts ' ' * @productions.length + prod
      @productions << prod
    end

    def onFinish
      prod = @productions.pop()
      $stdout.puts ' ' * @productions.length + '/' + prod
    end

    def onToken(prod, tok)
      $stdout.puts ' ' * @productions.length + "#{prod}(#{tok})"
    end
    
    def dump_stack(stack)
      STDERR.puts "\nstack trace:"
      stack.reverse.each do |se|
        STDERR.puts "#{se[:prod]}"
        STDERR.puts "  " + case se[:terms]
        when nil then "nil"
        when [] then "empty"
        else          se[:terms].join(",\n  ")
        end
      end
    end
    
    def test(input, branches, regexps)
      # FIXME: for now, read in entire doc, eventually, process as stream
      @input = input.respond_to?(:read) ? (input.rewind; input) : StringIO.new(input.to_s)
      @lineno = 0
      readline  # Prime the pump
      $stdout ||= STDOUT
      
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