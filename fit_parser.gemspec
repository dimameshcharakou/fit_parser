# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fit_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'fit_parser'
  spec.version       = FitParser::VERSION
  spec.authors       = ['Dima Mescheryakov']
  spec.email         = ['dima.mescheryakov@gmail.com']
  spec.summary       = ''
  spec.description   = 'handles FIT files'
  spec.homepage      = 'https://github.com/zhublik/fit_parser'
  spec.license       = 'MIT'

  spec.files         = Dir['{lib,spec}/**/*']
  spec.executables   = spec.files.grep(%r{^bin/[^.]+$}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'bindata', '2.2.0'
  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'warder'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'simplecov'
end
