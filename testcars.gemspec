# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'testcars/version'

Gem::Specification.new do |spec|
  spec.name          = "testcars"
  spec.version       = Testcars::VERSION
  spec.authors       = ["szaretsky"]
  spec.email         = ["szaretsky@gmail.com"]

  spec.summary       = %q{Test cars ETA service and web service.}
  spec.homepage      = "https://github.com/szaretsky/test_cars"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "eventmachine"
  spec.add_development_dependency "msgpack"
  spec.add_development_dependency "pg/em"
  spec.add_development_dependency "haversine"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "em-http-server"
end
