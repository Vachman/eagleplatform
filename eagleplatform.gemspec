# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eagleplatform/version"

Gem::Specification.new do |s|
  s.name        = "eagleplatform"
  s.version     = Eagleplatform::VERSION
  s.authors     = ["Vachagan Gevorkyan"]
  s.email       = ["va4@deultonmedia.com"]
  s.homepage    = ""
  s.summary     = %q{Eagleplatform API library}
  s.description = %q{Eagleplatform API library for crud records, translations etc. For more infromation see documentation }

  s.rubyforge_project = "eagleplatform"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rest-client'
  s.add_dependency 'json'
end
