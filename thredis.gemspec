# -*- ruby -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'thredis/version'

Gem::Specification.new do |gem|
  gem.name          = "thredis"
  gem.version       = Thredis::VERSION
  gem.authors       = ["Grisha Trubetskoy"]
  gem.email         = ["grisha@apache.org"]
  gem.description   = %q{Thredis DB datapter}
  gem.summary       = %q{Allows you to connect to Thredis}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('redis')
end
