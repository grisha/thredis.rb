# -*- ruby -*-

Gem::Specification.new do |gem|
  gem.name          = "thredis"
  gem.version       = "0.0.2"
  gem.authors       = ["Grisha Trubetskoy"]
  gem.email         = ["grisha@apache.org"]
  gem.description   = %q{Thredis DB adapter}
  gem.summary       = %q{Allows you to connect to Thredis}
  gem.homepage      = ""
  gem.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE.txt", "*.md"]
  gem.require_paths = ["lib"]

  gem.add_dependency('redis')
end
