# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ut/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Roger Jungemann"]
  gem.email         = ["rogerjungemann@google.com"]
  gem.description   = %q{The ultimate task management tool for Rally.}
  gem.summary       = %q{Manage tasks in your iterations, one story at a time.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "ut"
  gem.require_paths = ["lib"]
  gem.version       = Ut::VERSION
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_runtime_dependency 'rally_rest_api'
  gem.add_runtime_dependency 'nokogiri'
end

