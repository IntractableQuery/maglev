class Regexp
  class_primitive_nobridge '__new', 'new:options:lang:'  

  primitive_nobridge '_matchCbytes_from_limit_string*', '_matchCBytes:from:limit:string:'

  # definitions of ONCE .. ENC_UTF8 moved to racc_def_parser.rb
end
MagRp.freeze_consts(Regexp)

module MagRp

class RpStringScanner
  # derived from  Maglev lib/ruby/1.8/strscan.rb

  Id = "bite me $Id".freeze
  Version = "1.0.0".freeze

  def pos
    @pos
  end
  def match
    @match
  end
  def string
    @string
  end
  def limit
    @limit
  end
  def parser
    @parser
  end

  # def initialize(string) ; end # in strscan2.rb

  # replicate constant so it can be resolved at boot compile time in strscan2.rb
  CByteArray = FFI::CByteArray 

  def set_pos_limit(pos, lim)
    @pos = pos
    @limit = lim
  end

  def reset
    # @prev_pos = 0  # not used by lexer
    @pos = 0
    @match = nil
    self
  end

  # character types to meet needs of lexer
  CTYPE_WHITE = 0      # WHITE types do not include the \n end-of-line character
  CTYPE_VT_WHITE = 1
  CTYPE_OTHER = 3
  CTYPE_EOF = 4
  CTYPE_SIGN = 5

  CTYPE_DIGIT = 7  # decimal digit 0..9
  CTYPE_UNDERSCORE = 8
  CTYPE_LC_ALPHA = 9  #  a..z 
  CTYPE_UC_ALPHA = 10 #  A..Z

  def self.build_char_types
    s = String.new
    s.size=(256)
    for n in 0..255
      s[n] = CTYPE_OTHER
    end
    s[ ?\  ] = CTYPE_WHITE # space
    s[ ?\t ] = CTYPE_WHITE
    s[ ?\r ] = CTYPE_WHITE
    s[ ?\f ] = CTYPE_WHITE
    s[ ?\13 ] = CTYPE_VT_WHITE  # 13 = '\v' 
    s[ 004  ] = CTYPE_EOF
    s[ 032  ] = CTYPE_EOF
    s[ 000  ] = CTYPE_EOF
    s[ ?+ ] = CTYPE_SIGN
    s[ ?- ] = CTYPE_SIGN
    s[ ?_ ] = CTYPE_UNDERSCORE
    for n in ?a..?z 
      s[n] = CTYPE_LC_ALPHA 
    end
    for n in ?A..?Z 
      s[n] = CTYPE_UC_ALPHA 
    end
    for n in ?0..?9 
       s[n] =  CTYPE_DIGIT 
    end
    s.freeze 
    s
  end
    
  CTYPES_ARR = self.build_char_types  

  def pos=(n)
    n = Type.coerce_to(n, Fixnum, :to_int)
    raise RangeError, "xxx" if n > @string.size
    @pos = n
  end


  def [](n)
    # coercion will be implicit by match[] primitive
    # n = Type.coerce_to(n, Fixnum, :to_int)
    @match[n]
  end

  def beginning_of_line?
    p = @pos
    if p._equal?(0) 
      return true
    end
    @cbytearray[p - 1]._equal?( ?\n  )
  end

  def eos?
    @pos >= @limit
  end

  def near_eos?(margin)
    @pos >= (@limit - margin)
  end

  def getch
    # scan(/./m)  # m modifier means . matches LF
    p = @pos 
    ch = @cbytearray[p]
    @pos = p + 1
    @match = nil
    ch
  end

  def inspect
    if defined? @string then
      rest = string.size > 5 ? string[pos..pos+4] + "..." : string
      r = if eos? then
            "#<RpStringScanner fin>"
          elsif pos > 0 then
            prev = string[0...pos].inspect
            "#<RpStringScanner #{pos}/#{string.size} #{prev} @ #{rest.inspect}>"
          else
            "#<RpStringScanner #{pos}/#{string.size} @ #{rest.inspect}>"
          end
      # r.taint if self.string.tainted?
      r
    else
      "#<RpStringScanner (uninitialized)>"
    end
  end

  def matched
    # match.to_s if matched?
    m = @match
    m.to_s if (not m._equal?(nil)) 
  end

  def matched?
    not @match._equal?(nil)
  end

  def matched_size
    m = @match
    m.to_s.size if (not m._equal?(nil))
  end

  def rest
    # used for error messages only
    @string[@pos..-1]
  end

  def peek( len)
    unless len._isFixnum
      raise TypeError,'expected Fixnum'
    end
    if len <= 0
      raise ArgumentError if len < 0
      return "" 
    end
    return @string[@pos, len]
  end

  def scan( pattern)
    # was _scan_headonly( pattern, true, true) .
    # now inline  _scan_headonly_succptr_getstr(pattern)
    unless pattern._isRegexp
      raise ArgumentError, 'expected a Regexp'
    end
    ppos = @pos
    sstring = @string

    # _matchCbytes... prim returns nil if @pos >= @limit
    mmatch = pattern._matchCbytes_from_limit_string(@cbytearray, ppos, @limit, *@string)
    @match = mmatch

    return nil unless  mmatch

    m_size = mmatch.end(0) - ppos 
    @pos = ppos + m_size
    sstring[ppos, m_size]
  end

  def check_advance( pattern)
    #  like scan , but with boolean result, not matched string
    unless pattern._isRegexp
      raise ArgumentError, 'expected a Regexp'
    end
    ppos = @pos

    # _matchCbytes... prim returns nil if @pos >= @limit
    mmatch = pattern._matchCbytes_from_limit_string(@cbytearray, ppos, @limit, *@string)
    @match = mmatch

    return nil unless  mmatch

    m_size = mmatch.end(0) - ppos 
    @pos = ppos + m_size
    true
  end

  def check( pattern)
    # was _scan_headonly(pattern, false, true) .
    # now inline _scan_headonly(pattern)
    unless pattern._isRegexp
      raise ArgumentError, 'expected a Regexp'
    end

    # _matchCbytes... prim returns nil if @pos >= @limit
    mmatch = pattern._matchCbytes_from_limit_string(@cbytearray, @pos, @limit, *@string)
    @match = mmatch

    return mmatch  # nil or a MatchData
  end

  # see additional code in strscan2.rb
end
MagRp.freeze_consts(RpStringScanner)

class RubyLexer
  # replicate some constants heavily used by lexer so they
  #  can be resolved at bootstrap compile time
  CTYPE_DIGIT = RpStringScanner::CTYPE_DIGIT
  CTYPE_EOF = RpStringScanner::CTYPE_EOF
  CTYPE_SIGN = RpStringScanner::CTYPE_SIGN
end

end  # MagRp
