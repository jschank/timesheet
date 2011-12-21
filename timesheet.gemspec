# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "timesheet/version"

Gem::Specification.new do |s|
  s.name               = "timesheet"
  s.version            = Timesheet::VERSION
  s.date               = "2010-10-25"
  s.authors            = ["John F. Schank III"]
  s.email              = ["jschank@mac.com"]
  s.homepage           = "http://github.com/jschank/timesheet"
  s.summary            = "Timesheet is simple ruby application for tracking time spent on projects"
  s.default_executable = "timesheet"
  s.description        = "Timesheet is simple ruby application for tracking time spent on projects.
It is a console application that uses a simple text file storage back-end (YAML::Store)

The main idea is to be able to produce reports of hours spent, such that I can use geektool to display the reports."

  s.rubyforge_project  = "timesheet"

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths      = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "syntax"
  
  s.add_runtime_dependency "richunits"
  s.add_runtime_dependency "chronic"
  
end
