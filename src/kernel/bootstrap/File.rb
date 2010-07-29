# -*- coding: utf-8 -*-
# File in Ruby is identically Smalltalk GsFile
class File

  ALT_SEPARATOR  = nil
  PATH_SEPARATOR = ':'
  SEPARATOR      = '/'
  Separator      = SEPARATOR

  Stat = __resolve_smalltalk_global(:GsFileStat)

  class_primitive_nobridge '__section2OpenConstants', '_section2OpenConstants'

  FNM_SYSCASE  = 0x00
  FNM_NOESCAPE = 0x01
  FNM_PATHNAME = 0x02
  FNM_DOTMATCH = 0x04
  FNM_CASEFOLD = 0x08

  SEEK_SET     = 0            # set file position to offset
  SEEK_CUR     = 1            # set file position to current + offset
  SEEK_END     = 2            # set file position to end of file + offset

# Following constants are OS independent values different than
#  any found on common variants of Unix. They are translated to
#  OS dependent values by the primitives.  Use of other hardcoded values
#  will cause Exceptions during file opening.
  APPEND = self.__section2OpenConstants[:RUBY_APPEND]
  CREAT = self.__section2OpenConstants[:RUBY_CREAT]
  EXCL = self.__section2OpenConstants[:RUBY_EXCL]
  NOCTTY = self.__section2OpenConstants[:RUBY_NOCTTY]
  NONBLOCK = self.__section2OpenConstants[:RUBY_NONBLOCK]
  RDONLY = self.__section2OpenConstants[:RUBY_RDONLY]
  RDWR = self.__section2OpenConstants[:RUBY_RDWR]
  SYNC = self.__section2OpenConstants[:RUBY_SYNC]
  TRUNC = self.__section2OpenConstants[:RUBY_TRUNC]
  WRONLY = self.__section2OpenConstants[:RUBY_WRONLY]
#  see also File::Constants in IO2.rb

# FILE::LOCK  constants initialized below

  primitive '__close', 'close'

  primitive '__disable_autoclose', '_disableAutoClose'

  def close
    if self.__is_open 
      self.__close
    else
      raise IOError, 'already closed'
    end
    nil 
  end

  primitive_nobridge '__write', 'write:from:'
  primitive_nobridge '__getc', 'nextByte'
  primitive_nobridge '__peek_byte', 'peekByte'
  primitive_nobridge '__next_line_to', 'nextLineTo:'
  primitive_nobridge '__at_end', 'atEnd'
  primitive_nobridge '__next', 'next:'
  primitive_nobridge '__contents', 'contents'  # zero arg variant

  primitive '__read_into', '_read:into:readAhead:'
  primitive '__flush', 'flush'
  primitive '__rewind', 'rewind'
  primitive_nobridge '__is_open', 'isOpen'
  primitive_nobridge '__last_err_string', 'lastErrorString'
  primitive_nobridge '__last_err_code', 'lastErrorCode'
  primitive_nobridge '__readable', '_isReadable'
  primitive_nobridge '__seek', '_seekTo:opcode:'

  class_primitive_nobridge '__fstat','fstat:isLstat:'

  # _stat will return either a stat object or ERRNO
  class_primitive_nobridge '__stat_isLstat','stat:isLstat:'
  class_primitive_nobridge '__umask', '_umask:'

  class_primitive_nobridge '__open', '_rubyOpen:mode:permission:'  # 1st is String, 2nd,3rd are ints
  class_primitive_nobridge '__fopen', '_rubyFopen:mode:' # path is String or Fixnum, mode is a String
              # first arg determines use of fdopen or open
  class_primitive 'stdin', '_stdinServer'
  class_primitive '__stdin', '_stdinServer'
  class_primitive 'stdout', '_stdoutServer'
  class_primitive 'stderr', '_stderrServer'
  class_primitive_nobridge '__environmentAt', '_expandEnvVariable:isClient:'
  class_primitive_nobridge '__delete', 'removeServerFile:'


  # For Dir.rb
  class_primitive_nobridge '__dir_contents', 'contentsOfDirectory:onClient:'

  # __modify_file provides access to chmod, fchmod, chown, lchown, fchown
  class_primitive '__modify_file*', '_modifyFile:fdPath:with:with:'

  class_primitive_nobridge 'allocate', '_basicNew'

  def self.atime(filename)
    File.stat(filename).atime
  end

  def self.__stat(name, is_lstat)
    unless name._equal?(nil)
      name = Type.coerce_to(name, String, :to_str)
    end
    __stat_isLstat(name, is_lstat)
  end

  # TODO: consider using FFI to call libc basename
  def self.basename(filename, suffix='')
    fn = Type.coerce_to(filename, String, :to_str).squeeze('/')
    sf = Type.coerce_to(suffix, String, :to_str)

    return '/' if fn.eql?('/')

    b = fn.split('/')[-1]
    return '' if b._equal?(nil)

    if suffix.eql?('.*')
      index = b.rindex('.')
    else
      index = b.rindex(suffix)
      if (not index._equal?(nil)) && ((index + suffix.size) != b.size)
        index = nil
      end
    end
    return index._equal?(nil) ? b : b[0,index]
  end

  def self.blockdev?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.blockdev?
  end

  def self.chardev?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.chardev?
  end

  def self.chmod(permission, *file_names)
    perm = Type.coerce_to(permission, Fixnum, :to_int)
    count = 0
    file_names.each { |a_name|
      nam = Type.coerce_to(a_name, String, :to_str)
      status = File.__modify_file( 1, nam, perm, nil)
      if (status._equal?(0))
        count = count + 1
      end
    }
    return count
  end

  def self.chown(owner, group, *file_names)
    count = 0
    file_names.each { |a_name|
      status = File.__modify_file( 3, a_name, owner, group)
      if (status._equal?(0))
        count = count + 1
      end
    }
    return count
  end

  def self.ctime(filename)
    File.stat(filename).ctime
  end

  def self.delete(*file_names)
    count = 0
    file_names.each { |a_name|
      nam = Type.coerce_to(a_name, String, :to_str)
      status = File.__modify_file( 0, nam, nil, nil )
      if (status._equal?(0))
        count = count + 1
      else
        Errno.raise_errno(status, nam)
      end
    }
    return count
  end

  def self.directory?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.directory?
  end

  def self.dirname(string)
    nam = Type.coerce_to(string, String, :to_str) 
    File.__modify_file( 14, nam, nil, nil)  # section 3 dirname()
  end

  def self.executable?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.executable?
  end

  def self.executable_real?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.executable_real?
  end

  def self.exist?(path)
    stat_obj = self.__stat(path, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    true
  end

  def self.exists?(path)
    self.exist?(path)
  end

  # Convert path to an absolute pathname. If no directory is given,
  # relative paths are rooted at the current working directory.
  # Otherwise directory will be prefixed to the path. Tilde expansion is
  # done on the path.  Replaces '.' and '..' in the path with the
  # appropriate path components.  Does not coalesce contiguous '/'s.
  def self.expand_path(a_path, a_dir = nil)
    path = Type.coerce_to(a_path, String, :to_str) 

    dir = a_dir._equal?(nil) ? Dir.pwd : Type.coerce_to(a_dir, String, :to_str)
    dir = Dir.pwd if dir.empty?
    dir = __tilde_expand(dir)
    dir = __cannonicalize(dir)
    return dir if path.empty?

    path = __tilde_expand(path)
    if path[0] !=  SEPARATOR[0] # relative path
      path = File.join(dir, path)
    end
    __cannonicalize(path)
  end

  # Remove .. and . from path
  def self.__cannonicalize(path)
    if path['.']
      new_parts = []
      path.split(SEPARATOR).each do |component|
        case component
        when '..'
          new_parts.pop
        when '.'
          # nothing: just skip it
        when ''
          # The split
        else
          new_parts << component
        end
      end
      res = "#{SEPARATOR}#{new_parts.join(SEPARATOR)}"
    else
      res = path.dup
    end
    # remove trailing separator, if any
    sep_siz = SEPARATOR.size
    res_siz = res.size
    if res_siz > sep_siz &&  res[res_siz - sep_siz, sep_siz] == SEPARATOR
      res.size=(res_siz - sep_siz)
    end
    res
  end

  def self.__tilde_expand(path)
    case path[0,2]
    when '~':   ENV['HOME']
    when '~/':  ENV['HOME'] + path[1..-1]
    when /^~([^\/])+(.*)/
      raise NotImplementedError, "Don't handle ~user expansion yet"
    else
      path
    end
  end

  def self.extname(filename)
    base = self.basename(filename)
    index = base.rindex('.')
    return '' if index._equal?(nil) || index == (base.size - 1) || index == 0
    base[index..-1]
  end

  def self.file?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.file?
  end

  # MNI: File.fnmatch
  # MNI: File.fnmatch?

  def self.ftype(*names)
    unless names.length._equal?(1)
      raise ArgumentError , 'expected 1 arg'
    end
    File.stat(names[0]).ftype
  end

  def self.grpowned?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.grpowned?
  end

  def self.identical?(file_1, file_2)
    stat_1 = self.__stat(Type.coerce_to(file_1, String, :to_str), false)
    stat_2 = self.__stat(Type.coerce_to(file_2, String, :to_str), false)
    return false unless stat_1.ino == stat_2.ino
    return false unless stat_1.ftype == stat_2.ftype
#     return false unless POSIX.access(orig, R_OK)
#     return false unless POSIX.access(copy, R_OK)
    return true
  end

  def self.lchmod(permission, *file_names)
    # not supported , lchmod() not available on Linux or Solaris
    raise NotImplementedError
  end

  def self.lchown(owner, group, *file_names)
    count = 0
    file_names.each { |a_name|
      status = File.__modify_file( 4, a_name, owner, group)
      if (status._equal?(0))
        count = count + 1
      end
    }
    return count
  end

  def self.link(oldname, newname)
    old_nam = Type.coerce_to(oldname, String, :to_str)
    new_nam = Type.coerce_to(newname, String, :to_str)
    status = File.__modify_file(8, old_nam, new_nam)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File.link failed')
    end
    status
  end

  def self.lstat(filename)
    stat_obj = __stat(filename, true)
    if stat_obj._isFixnum
      # an error attempting to stat
      Errno.raise_errno(stat_obj, 'File.stat failed')
    end
    stat_obj
  end

  def self.mtime(filename)
    File.stat(filename).mtime
  end


  def self.new(filename, mode=MaglevUndefined, permission=MaglevUndefined)
    self.__create(filename, mode, permission)
  end

  def self.open(filename, mode=MaglevUndefined, permission=MaglevUndefined, &block)
    self.__create(filename, mode, permission, &block)
  end

  def self.__create(filename, mode, permission, &block)
    # __create is needed by  Tempfile implementation
    if filename._isInteger
      raise TypeError , 'File.new(fd_integer)  not supported yet'
    end
    filename = Type.coerce_to(filename, String, :to_str)
    nargs = 1
    if mode._equal?(MaglevUndefined)
      mode = 'r'
      nargs = 2
    else
      if permission._equal?(MaglevUndefined)
        nargs = 2
      else
        unless permission._isFixnum
          raise TypeError, 'third arg not a Fixnum '
        end
        nargs = 3
      end
    end
    if nargs._equal?(2)
      if mode._isString
        f = self.__fopen(filename, mode)
      elsif mode._isFixnum
        f = self.__open(filename, mode, -1)
      else
        raise TypeError, 'second arg neither Fixnum nor String'
      end
    else
      if mode._isFixnum
        f = self.__open(filename, mode, permission)
      else
        stat_obj = self.__stat(filename, false) # does file exist before we create?
        f = self.__fopen(filename, mode)
        Errno.raise_errno(stat_obj, filename) if f._equal?(nil)
        f.chmod(permission) if stat_obj._isFixnum # chmod new files (if couldn't stat it)
      end
    end

    Errno.raise_errno(f, filename ) if f._isFixnum

    if block_given?
      begin
        block.call(f)
      ensure
        begin
          f.close 
        rescue StandardError
          nil
        end
      end
    else
      f
    end
  end

  def self.owned?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.owned?
  end

  def self.pipe?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.pipe?
  end

  def self.readable?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.readable?
  end

  def self.readable_real?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.readable_real?
  end

  def self.readlink(filename)
    res = String.new
    status = File.__modify_file(9, filename, res)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File.readlink failed')
    end
    res
  end

  def self.rename(oldname, newname)
    oldname = Type.coerce_to(oldname, String, :to_str)
    newname = Type.coerce_to(newname, String, :to_str)
    status = File.__modify_file(7, oldname, newname)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File.rename failed')
    end
  end

  def self.setgid?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.setgid?
  end

  def self.setuid?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.setuid?
  end

  def self.size(filename)
    if filename._is_a?(File)
      filename = filename.path 
    end
    File.stat(filename).size
  end

  def self.size?(filename)
    if filename._is_a?(File)
      filename = filename.path 
    end
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return nil  # an error attempting to stat
    end
    stat_obj.size?
  end

  def self.socket?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.socket?
  end

  def self.split(arg)
    arg = Type.coerce_to(arg, String, :to_str)
    if arg.size._equal?(0)
      return [ '.' , '' ]
    end
    str = arg.dup
    changed = true
    until changed._equal?(nil)
      changed = str.gsub!('//', '/') 
    end
    idx = str.rindex('/')
    if idx._equal?(str.size - 1)
      str.size=(str.size - 1)
    end
    idx = str.rindex('/')
    if idx._equal?(nil) 
      return [ '.', str ]
    end 
    if idx._equal?(0)
      left = '/' 
    else
      left = str[0, idx] 
    end
    [ left , str[idx+1, str.size - idx - 1] ]
  end
  

  def self.stat(filename)
    stat_obj = Errno.handle(__stat(filename, false), filename)
    stat_obj
  end

  def self.sticky?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.sticky?
  end

  def self.symlink(oldname, newname)
    oldname = Type.coerce_to(oldname, String, :to_str)
    newname = Type.coerce_to(newname, String, :to_str)
    status = File.__modify_file(6, oldname, newname)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File.symlink failed')
    end
    status
  end

  def self.symlink?(filename)
    stat_obj = self.__stat(filename, true) # lstat()
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.symlink?
  end

  def self.truncate(filename, newsize)
    filename = Type.coerce_to(filename, String, :to_str)
    newsize = Type.coerce_to(newsize, Fixnum, :to_int)
    status = File.__modify_file(2, filename, newsize)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File.truncate failed')
    end
    status
  end

  def self.umask
    # return current file creation mask
    __umask(-1)
  end

  def self.umask(newmask)
    # set file creation mask to newmask and return previous value
    # newmask must be >= 0 and <= 0777
    newmask = Type.coerce_to(newmask, Fixnum, :to_int)
    if (newmask >= 0)
      res = __umask(newmask)
    else
      res = -1
    end
    if (res < 0)
      raise RangeError
    end
    res
  end

  def self.unlink(*file_names)
    delete(*file_names)
  end

  def self.utime(accesstime, modtime, *filenames)
    if accesstime._isFixnum
      a_time = accesstime
    elsif accesstime._is_a?(Time)
      a_time = accesstime.seconds
    else
      raise TypeError, 'File.utime, accesstime must be a Time or Fixnum'
    end
    if accesstime._isFixnum
      m_time = modtime
    elsif accesstime._is_a?(Time)
      m_time = modtime.seconds
    else
      raise TypeError, 'File.utime, modtime must be a Time or Fixnum'
    end
    count = 0
    filenames.each { |a_name|
      status = File.__modify_file( 5, a_name, a_time, m_time)
      if (status._equal?(0))
        count = count + 1
      end
    }
    return count
  end

  def self.writable?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.writable?
  end

  def self.writable_real?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.writable_real?
  end

  def self.zero?(filename)
    stat_obj = self.__stat(filename, false)
    if (stat_obj._isFixnum)
      return false  # an error attempting to stat
    end
    stat_obj.zero?
  end

  # BEGIN Instance methods

  def atime
    self.stat.atime
  end

  def chmod(arg)
    permission = Type.coerce_to(arg, Fixnum, :to_int)
    status = File.__modify_file( 10, @_st_fileDescriptor, permission, nil)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File#chmod failed')
    end
    return 0
  end

  def chown(owner, group)
    status = File.__modify_file( 12, @_st_fileDescriptor, owner, group)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File#chown failed')
    end
    return 0
  end

  def closed?
    not __is_open
  end

  def ctime
    self.stat.ctime
  end

  def eof?
    unless self.__readable
      raise IOError , 'file not opened for read'
    end
    status = self.__at_end
    if (status._equal?(nil))
      raise IOError
    end
    status
  end

  def getc
    raise IOError, 'getc: closed stream' unless __is_open
    self.__getc  # a byte value or nil for eof
  end

  # --------- begin gets implementation  [

  def gets(*args)    # [  begin gets implementation
    raise ArgumentError, 'expected 0 or 1 arg with no block'
  end

  def gets(sep)
    __gets(sep, 0x31)
  end

  def gets
    __gets($/, 0x31)
  end

  # def __gets; end # implemented in IO

  def read(a1=MaglevUndefined, a2=MaglevUndefined)
    uu = MaglevUndefined
    if a2._equal?(uu)
      if a1._equal?(uu)
        self.read()
      else
        self.read(a1)
      end
    else
      self.__read(a1, a2)
    end
  end

  def __read(a_length, a_buffer)
    raise IOError, 'read: closed stream' unless self.__is_open
    unless a_length._equal?(nil)
      length = Type.coerce_to(a_length, Fixnum, :to_int)
      raise ArgumentError, "length must not be negative" if length < 0
      return nil if self.pos > self.stat.size
    end
    buffer = Type.coerce_to(a_buffer, String, :to_str)
    length = self.stat.size if length._equal?(nil)
    num_read = __read_into(length, buffer, true)
    if num_read._equal?(0)
      return a_length._equal?(nil)  ? '' : nil
    end
    raise IOError, 'error' if num_read._equal?(nil)
    buffer.size = num_read # truncate buffer
    buffer
  end

  def read(a_length)
    raise IOError, 'read: closed stream' unless self.__is_open
    if a_length._equal?(nil)
      self.__contents # read_all_bytes
    else
      length = Type.coerce_to(a_length, Fixnum, :to_int)
      raise ArgumentError, "length must not be negative" if length < 0
      if length._equal?(0)
        return ''
      end
      self.__next(length)
    end
  end

  def read
    raise IOError, 'read: closed stream' unless __is_open
    data = __contents 
    data = '' if data._equal?(nil)
    data
  end

  def readpartial(length, buffer=MaglevUndefined)
    raise IOError, 'read: closed stream' unless __is_open
    need_trunc = false
    length = Type.coerce_to(length, Fixnum, :to_int)
    if buffer._equal?(MaglevUndefined)
      buffer = ""
    else
      buffer = Type.coerce_to(buffer, String, :to_str)
      need_trunc = true
    end
    num_read = self.__read_into(length, buffer, false)
    raise IOError, 'error' if num_read._equal?(nil)
    if need_trunc
      buffer.size = num_read # truncate buffer
    end
    buffer
  end

  def sysread(a1=MaglevUndefined, a2=MaglevUndefined)
    uu = MaglevUndefined
    if a2._equal?(uu)
      if a1._equal?(uu)
        self.sysread()
      else
        self.sysread(a1)
      end
    else
      self.__sysread(a1, a2)
    end
  end

  def __sysread(length, buffer)
    str = self.read(length, buffer)
    if str._equal?(nil)
      raise EOFError, "End of file reached"
    end
    str
  end

  def sysread(length)
    str = self.read(length)
    if str._equal?(nil)
      raise EOFError, "End of file reached"
    end
    str
  end

  def sysread
    str = self.__contents
    if str._equal?(nil)
      raise EOFError, "End of file reached"
    end
    str
  end


  # during bootstrap,  send and __send__ get no bridge methods
  def send(sym)
    if (sym._equal?(:gets))
      return __gets($/ , 0x31)
    end
    super(sym)
  end

  def send(sym, arg)
    if (sym._equal?(:gets))
      return __gets(arg, 0x31)
    end
    super(sym, arg)
  end

  def __send__(sym)
    if (sym._equal?(:gets))
      return __gets($/ , 0x31)
    end
    super(sym)
  end

  def __send__(sym, arg)
    if (sym._equal?(:gets))
      return __gets(arg , 0x31)
    end
    super(sym, arg)
  end

  # --------- end gets implementation  ]

  # -------- flock implementation

  def self.fetch_flock_constants
    # returns [ LOCK_EX, LOCK_NB, LOCK_SH, LOCK_UN ] from VM
    #  they will be -1 on Solaris , where flock not supported
    arr = [ ]
    status = File.__modify_file(13, 0, arr)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File.fetch_flock_constants failed')
    end
    arr
  end

  LOCK_EX = fetch_flock_constants()[0]
  LOCK_NB = fetch_flock_constants()[1]
  LOCK_SH = fetch_flock_constants()[2]
  LOCK_UN = fetch_flock_constants()[3]

  def flock(lock_constant)
    status = File.__modify_file(11, @_st_fileDescriptor, lock_constant)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File#flock failed')
    end
    status
  end

  # -------- end flock

  def flush
    if closed?
      raise IOError, 'cannot flush a closed File'
    end
    self.__flush
  end

  def fsync
    if closed?
      raise IOError, 'cannot flush a closed File'
    end
    status = File.__modify_file(16, @_st_fileDescriptor, nil, nil)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File#fsync failed') 
    end
    0
  end
  
  def inspect
    str = super
    if closed? 
      str << ', closed' 
    end
    str
  end

  def lchmod(permission)
    # not supported , lchmod() not available on Linux or Solaris
    raise NotImplementedError
  end

  def lchown(owner, group)
    status = File.__modify_file( 4, @_st_pathName, owner, group)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File#lchown failed')
    end
    return 0
  end

  def lstat
    File.__stat(@_st_pathName, true)
  end

  primitive_nobridge '__line_editor_read', 'nextLineTo:prompt:'

  def line_editor_readline(prompt_string)
    sep = 10
    self.__line_editor_read(sep, prompt_string)
  end

  def mtime
    self.stat.mtime
  end

  def __mode
    @_st_mode
  end

  primitive_nobridge '__fopen', '_fopen:mode:'

  def reopen(arg1, mode=MaglevUndefined)
    uu = MaglevUndefined
    if arg1._isString
      path = arg1
      if mode._equal?(uu)
        mode = 'r'
      end
    elsif arg1._kind_of?(File)
      path = arg1.path
      if mode._equal?(uu)
        mode = arg1.__mode
      end
    else
      raise TypeError , 'File#reopen, first arg must be a File or a String'
    end
    unless mode._isString || mode._isFixnum
      raise TypeError, 'File#reopen, mode is neither Fixnum nor String'
    end
    unless self.closed?
      self.__close
    end
    f = self.__fopen(path, mode)
    Errno.raise_errno(f, path ) if f._isFixnum
    self
  end

  def rewind
    self.__rewind
    self.lineno=(0)
  end

  def path
    @_st_pathName
  end

  def stat
    if closed?
      raise IOError, 'File#stat on a closed File'
    end
    res = File.__fstat(@_st_fileDescriptor, false)
    if (res._isFixnum)
      Errno.raise_errno(status, 'File#stat failed')
    end
    return res
  end

  # each_line inherited from IO

  def seek(offset, whence = SEEK_SET)
    offset = Type.coerce_to(offset, Fixnum, :to_int)
    pos = __seek(offset, whence)
    if pos._equal?(nil)
      Errno.raise_errno(self.__last_err_code, 'seek failed')
    end
    0 
  end

  # Return the current offset (in bytes) of +io+
  primitive_nobridge '__pos', 'position'

  def pos
    if closed?
      raise IOError, 'IO#pos on closed IO'
    end
    self.__pos
  end

  # Seeks to the given position (in bytes) in +io+
  def pos=(offset)
    if closed?
      raise IOError, 'IO#pos on closed IO'
    end
    ofs = Type.coerce_to(offset, Fixnum, :to_int)
    seek(ofs, SEEK_SET)
  end

  alias tell pos

  def truncate(a_length) 
    a_length = Type.coerce_to(a_length, Fixnum, :to_int)
    status = File.__modify_file( 15, @_st_fileDescriptor, a_length, nil)
    unless status._equal?(0)
      Errno.raise_errno(status, 'File#truncate failed')
    end
    return 0
  end

  primitive 'ungetc', 'ungetByte:'  

  def write(arg)
    arg = Type.coerce_to(arg, String, :to_s)
    count = self.__write(arg.__size, arg)
    if count._equal?(nil)
      raise IOError , self.__last_err_string  # TODO: Errno::xxx
    end
    count
  end

  alias :syswrite :write

end
File.__freeze_constants

# STDIN, STDOUT, STDERR , $>  initialized by .mcz code in RubyContext
