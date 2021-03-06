#
# A ParseTree parser class for parsing MagLev files.  This file is used by
# the parsetree_parser.rb script to launch the MagLev parse service.
#
# Copyright 2009-2010 GemStone Systems, Inc. All rights reserved.

require 'rubygems'
gem 'ParseTree', '3.0.3'
require 'parse_tree'

class ParseTree
  attr_accessor :include_newlines
end

class Float
  def to_s
    sprintf('%.16e', self)   # fix Trac 358, default to_s is only %.14e
  end
end

class MaglevParser
  def initialize
    @pt = ParseTree.new(true)
  end

  def newlines=(boolean)
    @pt.include_newlines = boolean
  end

  def parse_file(path)
    self.parse(File.open(path).read, File.basename(path), 0)
  end

  def parse_string(string)
    self.parse(string, "(string)", 0)
  end

  def parse(source, filename="(string)", line=0, method=nil)
    begin
      sexp = @pt.parse_tree_for_str(source, filename, 0).first
      if method then
        # class, scope, block, *methods
        sexp.last.last[1..-1].find do |defn|
          defn[1] == method
        end
      else
        sexp
      end
    rescue Exception => ex
      sexp = [ :parse_error , ex.message ]
      return sexp
    end
  end
end
