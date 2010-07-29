require 'stringio'

module Zlib

  # The superclass for all exceptions raised by Ruby/zlib.
  class Error < StandardError; end

  # constants from zlib.h as linked into Gemstone libgcilnk.so
  ZLIB_VERSION = "1.2.5"

  Z_NO_FLUSH    =  0
  # Z_PARTIAL_FLUSH = 1 # will be removed, use Z_SYNC_FLUSH instead
  Z_SYNC_FLUSH    = 2
  Z_FULL_FLUSH    = 3  # inflate() will terminate a block of compressed data
  Z_FINISH        = 4
  Z_BLOCK         = 5  # deflate() will return at end of next block boundary,
                        #  or after the gzip header .
  Z_TREES         = 6

  Z_OK            = 0
  Z_STREAM_END    = 1
  Z_NEED_DICT     = 2
  Z_ERRNO        = (-1)
  Z_STREAM_ERROR = (-2)
  Z_DATA_ERROR   = (-3)
  Z_MEM_ERROR    = (-4)
  Z_BUF_ERROR    = (-5)
  Z_VERSION_ERROR = (-6)

  Z_NO_COMPRESSION     =    0
  Z_BEST_SPEED         =    1
  Z_BEST_COMPRESSION   =    9
  Z_DEFAULT_COMPRESSION = (-1)

  Z_FILTERED           = 1
  Z_HUFFMAN_ONLY       = 2
  Z_RLE                = 3
  Z_FIXED              = 4
  Z_DEFAULT_STRATEGY   = 0

  Z_DEFLATED   = 8

  # from zconf.h
  MAX_WBITS = 15 # 32K LZ77 window
  MAX_MEM_LEVEL = 9
  DEF_MEM_LEVEL = 9

  OS_UNIX     = 0x03
  OS_CODE = OS_UNIX

  # class Zlib::ZStream was defined during bootstrap in zlib_czstream.rb

  class GzipFile  # {

    class Error < Zlib::Error; end

    #SYNC            = Zlib::ZStream::UNUSED
    #HEADER_FINISHED = Zlib::ZStream::UNUSED << 1
    #FOOTER_FINISHED = Zlib::ZStream::UNUSED << 2

    FLAG_MULTIPART    = 0x2
    FLAG_EXTRA        = 0x4
    FLAG_ORIG_NAME    = 0x8
    FLAG_COMMENT      = 0x10
    FLAG_ENCRYPT      = 0x20
    FLAG_UNKNOWN_MASK = 0xc0

    EXTRAFLAG_FAST    = 0x4
    EXTRAFLAG_SLOW    = 0x2

    MAGIC1         = 0x1f
    MAGIC2         = 0x8b
    METHOD_DEFLATE = 8

    def self.wrap(io, &block)
      obj = self.new(io)
      if block_given? then
        begin
          yield obj
        ensure
          obj.close 
        end
      end
    end

    # TODO: protect against multiple calls to close, or a close after a finish
    def close
      io = finish()
      io.close if io.respond_to? :close
      io
    end

    def closed?
      @io._equal?(nil)
    end

    def comment
      raise Error, 'closed gzip stream' if @io.nil?
      @comment.dup
    end

    # def finish # subclass responsibility

    def finished?
      self.closed?()
    end

    # def footer_finished? # not implemented
    # def header_finished? # not implemented

    def mtime
      Time.at(@mtime)
    end

    def orig_name
      raise Error, 'closed gzip stream' if @io.nil?
      @orig_name.dup
    end

  end # }


  class GzipReader < GzipFile # {

    def initialize(io)
      @io = io
      @zstream = ZStream.open_read(io, Error) # Error resolves to GzipFile::Error
      super()
      arr = @zstream.read_header()
      @orig_name = arr[0]
      @comment = arr[1]
      @mtime = arr[2]
    end
   
    def rewind 
      @zstream.close
      @io.rewind
      @zstream = ZStream.open_read(@io, Error)
      arr = @zstream.read_header()
      @orig_name = arr[0]
      @comment = arr[1]
      @mtime = arr[2]
      0
    end

    def eof?
      @zstream.at_eof
    end

    def pos
      sio = @contents_sio
      if sio._not_equal?(nil)
        sio.pos
      else
        @zstream.total_out()
      end
    end

    def read(length = nil)
      if length.nil?
        buf = ''
        while ! eof?
          buf << @zstream.read(16384)
        end
        buf
      else
        @zstream.read(length)
      end
    end

    def finish
      # does not call close method of the associated IO object.
      @zstream.close
      io = @io
      @io = nil
      io
    end

    def each_byte(&block)
      sio = self.__contents_sio
      sio.each_byte(&block)
      self
    end

    def __contents_sio
      sio = @contents_sio
      if sio._equal?(nil)
        str = String.new
        while not eof?
	  buf = self.read(4096)
	  if buf._equal?(nil)
            return str
          end
          str << buf
        end
        sio = PureRubyStringIO.open(str)
        @contents_sio = sio
      end
      sio
    end
  
    def each_line(sep=$/, &block)
      sio = self.__contents_sio
      sio.each_line(sep, &block)
    end

    alias each each_line

    def getc
      sio = self.__contents_sio
      sio.getc
    end

    def gets(sep_string=nil)
      sio = self.__contents_sio
      if sep_string._equal?(nil)
        sio.__gets( $/ , 0x41)  # called via bridge meth
      else
        sio.__gets(sep_string, 0x31)
      end
    end

  end # }

  class GzipWriter < GzipFile  # {

    GzfError = GzipFile::Error 

    ##
    # Creates a GzipWriter object associated with +io+. +level+ and +strategy+
    # should be the same as the arguments of Zlib::Deflate.new.  The
    # GzipWriter object writes gzipped data to +io+.  At least, +io+ must
    # respond to the +write+ method that behaves same as write method in IO
    # class.

    def initialize(io, level = Z_DEFAULT_COMPRESSION,
                   strategy = Z_DEFAULT_STRATEGY)
      @level = level
      @strategy = strategy
      @io = io
      @mtime = 0
      @buffer = ''
      @bufsize = 0
      super()
    end

    def comment=(v)
      # Set the comment
      unless @zstream._equal?(nil) then
        raise GzfError, 'header is already written' # Error resolves to GzipFile::Error
      end
      @comment = v
    end

    def mtime=(time)
      unless @zstream._equal?(nil) then
        raise GzfError, 'header is already written' # Error resolves to GzipFile::Error
      end
      t = Integer(time)
      @mtime = t 
    end

    def orig_name=(v)
      # Set the original name
      unless @zstream._equal?(nil) then
        raise GzfError, 'header is already written' # Error resolves to GzipFile::Error
      end
      @orig_name = v
    end

    def __validate_string(obj)
      unless obj._equal?(nil)
        unless obj._isString
          raise ArgumentError, 'argument must be a String'
        end
      end
    end

    def write_header
      __validate_string(@orig_name)
      __validate_string(@comment)
      lev = @level
      if (lev < Z_DEFAULT_COMPRESSION || lev > Z_BEST_COMPRESSION)
        raise ArgumentError, 'compression level out of range'
      end
      @zstream = ZStream.open_write(@io, Error, lev) # Error resolves to GzipFile::Error
      tim = @mtime.to_i
      unless tim._isFixnum
        raise ArgumentError, 'mtime must be a Fixnum'
      end
      arr = [ @orig_name, @comment, tim]
      @zstream.write_header(arr)
    end

    def write(data)
      strm = @zstream
      if strm._equal?(nil)
        write_header
        strm = @zstream
      end
      unless data._isString
        data = String(data)
      end
      ds = data.length
      bs = @bufsize
      if (ds >= 1024)
        if bs > 0
          strm.write(@buffer, bs)
          @bufsize = 0
        end
        strm.write(data, ds)
      else
        if (bs >= 1024)
          strm.write(@buffer, bs)
          @bufsize = 0
          bs = 0
        end
        @buffer[bs, ds] = data
        @bufsize = bs + ds
      end
    end

    alias << write

    def finish
      strm = @zstream
      if strm._equal?(nil)
        write_header
        strm = @zstream
      end 
      bs = @bufsize
      if bs > 0
        strm.write(@buffer, bs)
        @bufsize = 0
      end
      if strm._not_equal?(nil)
        strm.flush  # writes footer
      end
      @zstream = nil
      io = @io
      @io = nil
      io
    end

  end # }


  # Zlib:Inflate is the class for decompressing compressed data.  Unlike
  # Zlib::Deflate, an instance of this class is not able to duplicate
  # (clone, dup) itself.
  class Inflate < ZStream
    # Decompress +string+.
    def self.inflate(string)
      inflate_stream = Zlib::Inflate.new
      buf = inflate_stream.inflate(string)
      inflate_stream.finish
      inflate_stream.close
      buf
    end

    def inflate(string)
      __open(false, StringIO.new(string), Error, Z_DEFAULT_COMPRESSION) # Error resolves to Zlib::Error
      self.flush_next_out
    end

    def <<(string)
      io = @ioObj
      if io._equal?(nil)
        __open(false, StringIO.new(string), Error, Z_DEFAULT_COMPRESSION)
      else
        @ioObj << string
      end
    end

    def flush_next_out
      buf = ''
      while ! at_eof 
        buf << read(2048)
      end
      buf
    end

    def finish
      flush_next_out
    end

    def close
      unless @isClosed
        @isClosed = true
        super()
      end
    end 

    def closed?
      @isClosed 
    end
    
    def finished?
      at_eof
    end
  end

#   class Deflate < ZStream

#     # Compresses the given +string+. Valid values of level are
#     # <tt>Zlib::NO_COMPRESSION</tt>, <tt>Zlib::BEST_SPEED</tt>,
#     # <tt>Zlib::BEST_COMPRESSION</tt>, <tt>Zlib::DEFAULT_COMPRESSION</tt>, and an
#     # integer from 0 to 9.
#     #
#     # This method is almost equivalent to the following code:
#     #
#     #   def deflate(string, level)
#     #     z = Zlib::Deflate.new(level)
#     #     dst = z.deflate(string, Zlib::FINISH)
#     #     z.close
#     #     dst
#     #   end
#     #
#     # TODO: what's default value of +level+?
#     def deflate(string, flush = Zlib::FINISH)

#     end
#   end
end
