module FFI

  # The smalltalk implementation classes
  class CLibrary
    PersistentLibraries = []
  end
  # do not CLibrary.__freeze_constants, so PersistentLibraries not frozen

  #  Specialised error classes

  # class TypeError < RuntimeError; end # don't define, specs are expecting ::TypeError

  class NullPointerError < RuntimeError; end  # TODO, fix C prims to use NullPointerError
                #   instead of ::ArgumentError

  class NotFoundError < LoadError; end

  class NativeError < LoadError; end

  class PlatformError < FFI::NativeError; end

  class SignatureError < NativeError; end

  # DEBUG , a dynamic constant in post_prims/ffi.rb

  module Library
    CURRENT_PROCESS = 'useCurrentProcess'
  end

  USE_THIS_PROCESS_AS_LIBRARY = Library::CURRENT_PROCESS # deprecated

  module Platform
    OS = "" # you must use Config::CONFIG['host_os']
      # because OS could change after you commit code

    ARCH = ""   # arch should be determined dynamically
    LIBPREFIX = "lib"
    LIBSUFFIX = "" # OS  dependent suffix appended at runtime by the
                   # library load primitives if '.' not in lib name,
                   #    or if '.' is last character of lib name.
    LONG_SIZE = 64 # in bits
    ADDRESS_SIZE = 64
    LIBC = 'libc'  # may need OS dependent logic eventually?
  end

  # Tables used to translate arguments for primitives.

  # Mapping from Ruby type names to type names supported by CFunction
  # If you add new keys to this dictionary, you must also
  # modify  CFunction(C)>>_addRubyPrimTypes in image/ruby/Capi_ruby.gs
  # and rexecute as SystemUser , if the new key is to be understood
  # as the type of a varArg argument.
  #
  PrimTypeDefs = IdentityHash.from_hash(
    { :char => :int8 ,  :uchar => :uint8 ,
      :short => :int16 , :ushort => :uint16 ,
      :int   => :int32 , :uint => :uint32 ,
      :long  => :int64 , :ulong => :uint64 ,
      :int8 => :int8,  :uint8 => :uint8 ,
      :int16 => :int16 , :uint16 => :uint16 ,
      :int32 => :int32 , :uint32 => :uint32 ,
      :int64 => :int64 , :uint64 => :uint64,
      :size_t => :uint64 ,
      :long_long => :int64 ,
      :ulong_long => :uint64 ,
      :float  =>  :float ,
      :double =>  :double ,
      :pointer => :ptr ,
      :ptr => :ptr ,
      :buffer_out => :ptr , # a Pointer written into by C function
      :buffer_in => :ptr  , # a Pointer read by C function
      :buffer_inout => :ptr  , # a Pointer read/written by C function
      :void => :void ,
      :string => :'char*' ,
      :'char*' => :'char*' ,
      :const_string => :'const char*'} )

  # Body of a  :const_string  argument is copied from object memory to C
  #   memory before a function call .
  # Body of a  :string  argument is copied from object memory to C memory
  #   before a function call, and is then copied back to object memory
  #   after the function call.

  # mapping from types supported by CFunction to sizes in bytes
  PrimTypeSizes = IdentityHash.from_hash(
    { :int8 => 1,  :uint8 => 1,
      :int16 => 2 , :uint16 => 2 ,
      :int32 => 4 , :uint32 => 4 ,
      :int64 => 8 , :uint64 => 8,
      :float =>  4 ,
      :double =>  8 ,
      :ptr => 8 ,
      :void => 8 ,
      :'char*' => 8,
      :'const char*' => 8 } )

  StructAccessors = IdentityHash.from_hash(
    # values are selectors for use with __perform_se
    { :char =>  :'get_uchar:' ,  :uchar => :'get_uchar:' ,
      :short => :'get_short:' , :ushort => :'get_ushort:' ,
      :int   => :'get_int:' , :uint => :'get_uint:' ,
      :long  => :'get_long:' , :ulong => :'get_ulong:' ,
      :int8 =>  :'int8at:',  :uint8 => :'get_uchar:' ,
      :int16 => :'get_short:' , :uint16 => :'get_ushort:' ,
      :int32 => :'get_int:' , :uint32 => :'get_uint:' ,
      :int64 => :'int64at:' , :uint64 => :'uint64at:' ,
      :size_t => :'uint64at:' ,
      :long_long => :'int64at:' ,
      :ulong_long => :'uint64at:' ,
      :float  =>  :'float_at:' ,
      :double =>  :'double_at:' ,
      :ptr => :'__struct_pointer_at:',
  #   :void => :void ,
      :'char*' => :'char_star_at:' ,
      :string => :'char_star_at:' ,
  #   :const_string => :'const char*'
       } )

  StructSetters = IdentityHash.from_hash(
   # values are selectors for use with __perform__se
    { :char => :'int8_put::' ,  :uchar => :'put_uchar::' ,
      :short => :'put_short::' , :ushort => :'put_ushort::' ,
      :int   => :'put_int::' , :uint => :'put_int::' ,
      :long  => :'int64_put::' , :ulong => :'int64_put::' ,
      :int8 => :'int8_put::',  :uint8 => :'put_uchar::' ,
      :int16 => :'put_short::' , :uint16 => :'put_short::' ,
      :int32 => :'put_int::' , :uint32 => :'put_int::' ,
      :int64 => :'int64_put::' , :uint64 => :'int64_put::' ,
      :size_t => :'int64_put::' ,
      :long_long => :'int64_put::' ,
      :ulong_long => :'int64_put::' ,
      :float  =>  :'float_put::' ,
      :double =>  :'double_put::' ,
      :ptr => :'__pointer_at_put::' ,
  #   :void => :void ,
      :'char*' => :'char_star_put::'
  #   :const_string => :'const char*'
       } )

  class Enums
    Persistent_Enums = []
    Persistent_NamedEnums = IdentityHash.new
    Persistent_kv_map = IdentityHash.new
    GsMethodDictionary =  __resolve_smalltalk_global(:GsMethodDictionary)

    def initialize
      raise 'instances of Enums not used yet'
    end

    # remainder in ffi_enum.rb
  end
  # do not Enums.__freeze_constants , Persistent_  may be added to

  class Enum
    def name
      @name
    end
    def tag
      @name
    end
    def symbol_map
      @kv_map
    end
    alias to_h symbol_map

    def __printable_name
      n = @name
      if name._equal?(nil)
        'unnamed'
      else
        n.to_s
      end
    end

    def __vk_map
      @vk_map
    end

    # remainder in ffi_enum.rb
  end

  # subclasses of Pointer

  class MemoryPointer < Pointer
    # all behavior inherited from Pointer
  end

  class AutoPointer < Pointer
    # All Maglev MemoryPointer's have auto-free behavior unless
    #  auto-free explicitly disabled on an instance
  end

  class Buffer < Pointer
    # all behavior is in Pointer
  end

  class Struct < Pointer
    # define the fixed instvars
    def __set_layout(ly)
      @layout = ly
    end

    # remainder of implementation in ffi_struct.rb
  end

  class Union < FFI::Struct # need FFI:: to properly resolve during bootstrap
  end

  # FFI definition of the layout of a C struct.  An instance of this class
  # is created and stored with the FFI Struct when Struct.layout is called.
  class StructLayout
    # define the fixed instvars
    def initialize
      @members_dict = IdentityHash.new # keys are Symbols,
               #  values are offsets into @members...@setters
      @members = []
      @offsets = []
      @sizes = []
      @elem_sizes = [] # used for array elements
      @accessors = []
      @setters = []
      @totalsize = 0
      @closed = false
      @alignment = 0
    end

    # remainder of implementation in ffi_struct.rb
  end

  # FFI definition of the layout of a C union.  An instance of this class
  # is created and stored with the FFI Union when Union.layout is called.
  class UnionLayout < StructLayout
  end

  class Type
    PersistentTypes = IdentityHash.new

    def initialize(a_sym, a_size, pt_sym)
      @name = a_sym
      @size = a_size # in bytes
      @prim_type_name = pt_sym # a name known to CFunction, or name of another Type
    end
  end

end
FFI.__freeze_constants

# the rest of the FFI implementation is in file ffi2.rb
