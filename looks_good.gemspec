# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "looks_good/version"

Gem::Specification.new do |s|
  s.name        = "looks_good"
  s.version     = LooksGood::VERSION
  s.authors     = ["Russell Jennings"]
  s.email       = ["violentpurr@gmail.com"]
  s.homepage    = "http://github.com/meesterdude/looks_good"
  s.summary     = %q{Rspec visual testing}
  s.description = %q{Rspec visual testing with percent matching tolerance}

  s.rubyforge_project = "looks_good"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('rmagick', ['>=2.15.4'])
  s.add_runtime_dependency('mini_magick', ['>=4.11.0'])
  s.add_runtime_dependency('capybara',['>=2.6.0'])

  s.add_development_dependency('rake',['>=0.9.2'])
  s.add_development_dependency('pry',['>=0.10.2'])
  s.add_development_dependency('selenium-webdriver',['~> 2.53.0'])
end
