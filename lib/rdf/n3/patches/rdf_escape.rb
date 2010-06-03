# coding: utf-8
require 'iconv'

class String
  #private
  # "Borrowed" from JSON utf8_to_json
  RDF_MAP = {
    "\x0" => '\u0000',
    "\x1" => '\u0001',
    "\x2" => '\u0002',
    "\x3" => '\u0003',
    "\x4" => '\u0004',
    "\x5" => '\u0005',
    "\x6" => '\u0006',
    "\x7" => '\u0007',
    "\b"  =>  '\b',
    "\t"  =>  '\t',
    "\n"  =>  '\n',
    "\xb" => '\u000B',
    "\f"  =>  '\f',
    "\r"  =>  '\r',
    "\xe" => '\u000E',
    "\xf" => '\u000F',
    "\x10" => '\u0010',
    "\x11" => '\u0011',
    "\x12" => '\u0012',
    "\x13" => '\u0013',
    "\x14" => '\u0014',
    "\x15" => '\u0015',
    "\x16" => '\u0016',
    "\x17" => '\u0017',
    "\x18" => '\u0018',
    "\x19" => '\u0019',
    "\x1a" => '\u001A',
    "\x1b" => '\u001B',
    "\x1c" => '\u001C',
    "\x1d" => '\u001D',
    "\x1e" => '\u001E',
    "\x1f" => '\u001F',
    '"'   =>  '\"',
    '\\'  =>  '\\\\',
    '/'   =>  '/',
  } # :nodoc:

  if defined?(::Encoding)
    # Funky way to define constant, but if parsed in 1.8 it generates an 'invalid regular expression' error otherwise
    eval %(ESCAPE_RE = %r([\u{80}-\u{10ffff}]))
  else
    ESCAPE_RE = %r(
                    [\xc2-\xdf][\x80-\xbf]    |
                    [\xe0-\xef][\x80-\xbf]{2} |
                    [\xf0-\xf4][\x80-\xbf]{3}
                  )nx
  end
  
  # Convert a UTF8 encoded Ruby string _string_ to an escaped string, encoded with
  # UTF16 big endian characters as \U????, and return it.
  #
  # \\:: Backslash
  # \':: Single quote
  # \":: Double quot
  # \n:: ASCII Linefeed
  # \r:: ASCII Carriage Return
  # \t:: ASCCII Horizontal Tab
  # \uhhhh:: character in BMP with Unicode value U+hhhh
  # \U00hhhhhh:: character in plane 1-16 with Unicode value U+hhhhhh
  def rdf_escape
    string = self + '' # XXX workaround: avoid buffer sharing
    string.gsub!(/["\\\/\x0-\x1f]/) { RDF_MAP[$&] }
    if defined?(::Encoding)
      string.force_encoding(Encoding::UTF_8)
      string.gsub!(ESCAPE_RE) { |c|
                      s = c.dump.sub(/\"\\u\{(.+)\}\"/, '\1').upcase
                      (s.length <= 4 ? "\\u0000"[0,6-s.length] : "\\U00000000"[0,10-s.length]) + s
                    }
      string.force_encoding(Encoding::ASCII_8BIT)
    else
      string.gsub!(ESCAPE_RE) { |c|
                      s = Iconv.new('utf-16be', 'utf-8').iconv(c).unpack('H*').first.upcase
                      "\\u" + s
                    }
    end
    string
  end
  
  # Unescape characters in strings.
  RDF_UNESCAPE_MAP = Hash.new { |h, k| h[k] = k.chr }
  RDF_UNESCAPE_MAP.update({
    ?"  => '"',
    ?\\ => '\\',
    ?/  => '/',
    ?b  => "\b",
    ?f  => "\f",
    ?n  => "\n",
    ?r  => "\r",
    ?t  => "\t",
    ?u  => nil, 
  })

  if defined?(::Encoding)
    UNESCAPE_RE = %r(
      (?:\\[\\bfnrt"/])   # Escaped control characters, " and /
      |(?:\\U00\h{6})     # 6 byte escaped Unicode
      |(?:\\u\h{4})       # 4 byte escaped Unicode
    )x
  else
    UNESCAPE_RE = %r((?:\\[\\bfnrt"/]|(?:\\u(?:[A-Fa-f\d]{4}))+|\\[\x20-\xff]))n
  end
  
  # Reverse operation of escape
  # From JSON parser
  def rdf_unescape
    return '' if self.empty?
    string = self.gsub(UNESCAPE_RE) do |c|
      case c[1,1]
      when 'U'
        raise RdfException, "Long Unicode escapes no supported in Ruby 1.8" unless defined?(::Encoding)
        eval(c.sub(/\\U00(\h+)/, '"\u{\1}"'))
      when 'u'
        bytes = [c[2, 2].to_i(16), c[4, 2].to_i(16)]
        Iconv.new('utf-8', 'utf-16').iconv(bytes.pack("C*"))
      else
        RDF_UNESCAPE_MAP[c[1]]
      end
    end
    string.force_encoding(Encoding::UTF_8) if defined?(::Encoding)
    string
  rescue Iconv::Failure => e
    raise RdfException, "Caught #{e.class}: #{e}"
  end
end