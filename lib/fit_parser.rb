require 'bindata'
require 'active_support'
require 'active_support/core_ext/class'
require 'fit_parser/file'
require 'fit_parser/file/header'
require 'fit_parser/file/record'
require 'fit_parser/file/record_header'
require 'fit_parser/file/types'
require 'fit_parser/file/type'
require 'fit_parser/file/definition'
require 'fit_parser/file/data'
require 'fit_parser/file/definitions'
require 'fit_parser/version'
require 'bindata/dsl_field_validator'

module FitParser
  def self.load_file(file)
    if File.instance_of? String
      return File.read(::File.open(file))
    else
      return File.read(file)
    end
  end
end
