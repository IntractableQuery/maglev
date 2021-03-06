
module MagRp

  class ScanError < StandardError; end

  class RaccJumpError < StandardError; end

  # deleted  Sexp, SexpMatchSpecial, SexpAny

  class InternalParseError < StandardError ; end

  class DefnNameToken < RpNameToken
    #  RpNameToken is a smalltalk class
    def line
      @line_num  # instVar defined by DefnNameToken,
      # all other instVars inherited from RpNameToken
    end
    def self.new(str, ofs, line)
      o = self.allocate
      o.initialize(str, ofs, line)
    end
    def initialize(str, ofs, line)
      @_st_val = str.__as_symbol
      @line_num = line
      @_st_src_offset = ofs
      self
    end
    def inspect
      "(DefnNameToken #{@_st_val}  @#{@_st_src_offset} line:#{@line_num})"
    end
  end

  class Environment # {
    # reworked from Ryans' code to reverse order of arrays, so that extend
    # can add to the end of the arrays, and unextend decrements curridx .
    # reworked to have a single array of triples to reduce
    #  instVar references

    #  env is @arr[@curridx] , dyn is @arr[@curridx+1], use is @arr[@curridx+2]

    # OFF_env = 0
    OFF_dyn = 1
    OFF_use = 2
    OFF_byte_offset = 3  # approximate location of  def , class, module
    ENTRY_SIZE = 4  # also hardcoded in initialize

    def initialize
      @src_scanner = nil
      @arr = []
      @curridx = - 4 # inline -ENTRY_SIZE , avoid dynamic const ref
      @extend_ofs_last_unextend = -1
      @first_top_level_def_offset = -1
      @module_count = 0
      @in_block_params = false
    end

    def last_closed_def_offset
      @extend_ofs_last_unextend
    end

    def first_top_level_def_offset
      @first_top_level_def_offset
    end

    def scanner=( scanner )
      @src_scanner = scanner
    end

    # end of first opening,  all constants and fixed instVars defined
  end # }
  MagRp.freeze_consts(Environment)

  class RubyLexer # {
    def command_start_
      @command_start
    end
    def cmdarg_
      @cmdarg
    end
    def cmdarg=( v )
      @cmdarg = v
    end
    def cond_
      @cond
    end
    def nest_
      @nest
    end
    def lineno_
      @line_num
    end
    def mydebug_
      @mydebug
    end

    def src_regions_
      @src_regions
    end

    # ESC_RE = /\\([0-7]{1,3}|x[0-9a-fA-F]{1,2}|M-.|(C-|c)\?|(C-|c).|[^0-7xMCc])/
    # ESC_RE is no longer used (after fix for Trac 580)

    CHAR_LIT_VT_WHITE_ERRS = {
                    " " => 's',
                    "\n" => 'n',
                    "\t" => 't',
                    "\v" => 'v',
                    "\r" => 'r',
                    "\f" => 'f' }

    UNESCAPE_TABLE = {
      "a"    => "\007",
      "b"    => "\010",
      "e"    => "\033",
      "f"    => "\f",
      "n"    => "\n",
      "r"    => "\r",
      "s"    => " ",
      "t"    => "\t",
      "v"    => "\13",
      "\\"   => '\\',
      "\n"   => "",
      "C-\?" => 0177.chr,
      "c\?"  => 0177.chr }

    # Additional context surrounding tokens that both the lexer and
    # grammar use.
    def lex_state_
      @lex_state
    end

    def lex_strTerm_
      @lex_strterm
    end
    def lex_strTerm=(v)
      if v._not_equal?(nil)           # TODO remove consistency check
        sym = v[0]
        unless sym._equal?( :strterm ) || sym._equal?( :heredoc )
          raise 'invalid arg to lex_strTerm='
        end
      end
      @lex_strterm = v
    end

    def parser_ # HACK for very end of lexer... *sigh*
      @parser
    end
    def parser=(p)
      @parser = p
    end

    def string_buffer_
      @string_buffer
    end

    # Stream of data that yylex examines.
    #  attr_reader :src
    def the_scanner
      @src_scanner
    end

    def source_string
      @src_scanner.string
    end

    # Value of last token which had a value associated with it.
    def yacc_value_
      @yacc_value
    end

    def line_num_
      # maintained by yylex and parsing of string constants
      @line_num
    end

    def _keyword_table
      @keyword_table  # a Hash , replaces Keyword.keyword
    end

    def last_else_src_offset
      @last_else_src_offset
    end

    EOF = :eof_haha!

    # ruby constants for strings (should this be moved somewhere else?)
    STR_FUNC_BORING = 0x00
    STR_FUNC_ESCAPE = 0x01 # TODO202: remove and replace with REGEXP
    STR_FUNC_EXPAND = 0x02
    STR_FUNC_REGEXP = 0x04
    STR_FUNC_AWORDS = 0x08
    STR_FUNC_SYMBOL = 0x10
    STR_FUNC_INDENT = 0x20 # <<-HEREDOC

    STR_SQUOTE = STR_FUNC_BORING
    STR_DQUOTE = STR_FUNC_BORING | STR_FUNC_EXPAND
    STR_XQUOTE = STR_FUNC_BORING | STR_FUNC_EXPAND
    STR_REGEXP = STR_FUNC_REGEXP | STR_FUNC_ESCAPE | STR_FUNC_EXPAND
    STR_SSYM   = STR_FUNC_SYMBOL
    STR_DSYM   = STR_FUNC_SYMBOL | STR_FUNC_EXPAND

    def self.build_strterm(arr)
      arr << Regexp.new(Regexp.escape(arr[2]))
      arr << "\0"
      arr << /\000/
      arr
    end

    STRTERM_DQUOTE = build_strterm( [ :strterm,  STR_DQUOTE, '"' ] )
    STRTERM_SSYM =   build_strterm( [ :strterm, STR_SSYM, "'" ] )
    STRTERM_DSYM =   build_strterm( [ :strterm, STR_DSYM, '"' ] )
    STRTERM_XQUOTE = build_strterm( [ :strterm, STR_XQUOTE, '`'] )
    STRTERM_REGEXP = build_strterm( [ :strterm, STR_REGEXP, '/'] )

    # define lexer states as bits in a Fixnum for more efficient testing
    #   of  one of several states
    Expr_beg =     0x1  # :expr_beg    = ignore newline, +/- is a sign.
    Expr_end =     0x2  # :expr_end    = newline significant, +/- is a operator.
    Expr_arg =     0x4  # :expr_arg    = newline significant, +/- is a operator.
    Expr_cmdArg =  0x8  # :expr_cmdarg = newline significant, +/- is a operator.
    Expr_endArg = 0x10  # :expr_endarg = newline significant, +/- is a operator.
    Expr_mid =    0x20  # :expr_mid    = newline significant, +/- is a operator.
    Expr_fname =  0x40  # :expr_fname  = ignore newline, no reserved words.
    Expr_dot =    0x80  # :expr_dot    = right after . or ::, no reserved words.
    Expr_class = 0x100  # :expr_class  = immediate after class, no here document.

    Expr_IS_argument = Expr_arg | Expr_cmdArg
    Expr_IS_fname_dot = Expr_fname | Expr_dot
    Expr_IS_beg_mid = Expr_beg | Expr_mid
    Expr_IS_beg_fname_dot_class = Expr_beg | Expr_fname | Expr_dot | Expr_class

    Expr_IS_beg_mid_class = Expr_beg | Expr_mid | Expr_class
    Expr_IS_end_endarg = Expr_end | Expr_endArg

    Expr_IS_argument_end = Expr_IS_argument | Expr_end

    Expr_IS_end_dot_endarg_class = Expr_end | Expr_dot | Expr_endArg | Expr_class

    Expr_IS_beg_mid_dot_arg_cmdarg = Expr_beg | Expr_mid | Expr_dot | Expr_arg | Expr_cmdArg

  end # }
  MagRp.freeze_consts(RubyLexer)

  class Keyword # {
#     class KWtable   # class no longer used
# attr_accessor :name, :state, :id0, :id1
# def initialize(name, id=[], state=nil)
#   @name  = name
#   @id0, @id1 = id
#   @state = state
# end
#      end

      ##
      # :stopdoc:
      #
      # lexer states changed to Fixnums, see rp_classes.rb
      #  Expr_beg    = ignore newline, +/- is a sign.
      #  Expr_end    = newline significant, +/- is a operator.
      #  Expr_arg    = newline significant, +/- is a operator.
      #  Expr_cmdarg = newline significant, +/- is a operator.
      #  Expr_endarg = newline significant, +/- is a operator.
      #  Expr_mid    = newline significant, +/- is a operator.
      #  Expr_fname  = ignore newline, no reserved words.
      #  Expr_dot    = right after . or ::, no reserved words.
      #  Expr_class  = immediate after class, no here document.

      WORDLIST = [
        # elements are  reserved word , a String
        #           kwarr [ a Symbol, a Symbol,  value for @lex_state ]
        # kwarr[0] == nil means special handling needed
        #         and new token is always kwarr[1]
        # kwarr[0] == 0 means no encapsulation in an RpNameToken.
        #         and new token is always kwarr[1]
        # kwarr[0] == 1 means encapsulate in an RpNameToken.
        #         and new token is always kwarr[1]
        # Any reserved word which can
        # also be a method name needs encapsulation in an RpNameToken.
      ["end",      [ 0,      :kEND        , RubyLexer::Expr_end   ]],
      ["else",     [ nil ,     :kELSE       , RubyLexer::Expr_beg   ]],
      ["case",     [ 1,     :kCASE       , RubyLexer::Expr_beg   ]],
      ["ensure",   [ 1,   :kENSURE     , RubyLexer::Expr_beg   ]],
      ["module",   [ 0,   :kMODULE     , RubyLexer::Expr_beg   ]],
      ["elsif",    [ 0,    :kELSIF      , RubyLexer::Expr_beg   ]],
      ["def",      [ nil ,      :kDEF        , RubyLexer::Expr_fname ]],
      ["rescue",   [:kRESCUE,   :kRESCUE_MOD , RubyLexer::Expr_mid   ]],
      ["not",      [ 1,      :kNOT        , RubyLexer::Expr_beg   ]],
      ["then",     [ 0,     :kTHEN       , RubyLexer::Expr_beg   ]],
      ["yield",    [ 1,    :kYIELD      , RubyLexer::Expr_arg   ]],
      ["for",      [ 1,      :kFOR        , RubyLexer::Expr_beg   ]],
      ["self",     [ 0,     :kSELF       , RubyLexer::Expr_end   ]],
      ["false",    [ 1,    :kFALSE      , RubyLexer::Expr_end   ]],
      ["retry",    [ 1,    :kRETRY      , RubyLexer::Expr_end   ]],
      ["return",   [ 1,   :kRETURN     , RubyLexer::Expr_mid   ]],
      ["true",     [ 1,     :kTRUE       , RubyLexer::Expr_end   ]],
      ["if",       [ :kIF,       :kIF_MOD     , RubyLexer::Expr_beg   ]],
      ["defined?", [ 1,  :kDEFINED    , RubyLexer::Expr_arg   ]],
      ["super",    [ 1,    :kSUPER      , RubyLexer::Expr_arg   ]],
      ["undef",    [ 1,    :kUNDEF      , RubyLexer::Expr_fname ]],
      ["break",    [ 1,    :kBREAK      , RubyLexer::Expr_mid   ]],
      ["in",       [ 1,       :kIN         , RubyLexer::Expr_beg   ]],
      ["do",       [ nil ,       :kDO         , RubyLexer::Expr_beg   ]],
      ["nil",      [ 0,      :kNIL        , RubyLexer::Expr_end   ]],
      ["until",    [:kUNTIL,    :kUNTIL_MOD  , RubyLexer::Expr_beg   ]],
      ["unless",   [:kUNLESS,   :kUNLESS_MOD , RubyLexer::Expr_beg   ]],
      ["or",       [ 0,       :kOR         , RubyLexer::Expr_beg   ]],
      ["next",     [ 1,     :kNEXT       , RubyLexer::Expr_mid   ]],
      ["when",     [ 1,     :kWHEN       , RubyLexer::Expr_beg   ]],
      ["redo",     [ 1,     :kREDO       , RubyLexer::Expr_end   ]],
      ["and",      [ 0,      :kAND        , RubyLexer::Expr_beg   ]],
      ["begin",    [ 0,    :kBEGIN      , RubyLexer::Expr_beg   ]],
      ["__LINE__", [ 0,     :k__LINE__   , RubyLexer::Expr_end   ]],
      ["class",    [ 1,    :kCLASS      , RubyLexer::Expr_class ]],
      ["__FILE__", [ 0,     :k__FILE__   , RubyLexer::Expr_end   ]],
      ["END",      [ 0,     :klEND       , RubyLexer::Expr_end   ]],
      ["BEGIN",    [ 0,   :klBEGIN     , RubyLexer::Expr_end   ]],
      ["while",    [:kWHILE,    :kWHILE_MOD  , RubyLexer::Expr_beg   ]],
      ["alias",    [ 1,    :kALIAS      , RubyLexer::Expr_fname ]]
     ]

      # def self.keyword( str)  ; end # no longer used

  end # }
  MagRp.freeze_consts(Keyword)

  class SrcRegion
    # describes a portion of the source string, used in heredoc implementation
    def initialize(lnum, ofs, lim)
      @line_num = lnum
      @offset = ofs
      @limit  = lim
    end
    def line_num
      @line_num
    end
    def offset
      @offset
    end
    def limit
      @limit
    end
  end

end

