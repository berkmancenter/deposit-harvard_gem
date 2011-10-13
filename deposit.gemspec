# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "deposit/version"

Gem::Specification.new do |s|
  s.name        = "deposit"
  s.version     = Deposit::VERSION
  s.authors     = ["Ryan Waldron"]
  s.email       = ["rew@erebor.com"]
  s.homepage    = "http://arcturo.com"
  s.summary     = %q{Deposit and retrieve documents in document repositories (SWORD, etc.).}
  s.description = %q{The deposit gem manages connections to multiple document repositories. Supports SWORD-compatible repositories (see http://swordapp.org for more about SWORD), and offers tools for uploading documents to multiple repositories with a single command. It also performs some simple caching, especially of service documents.}

  s.rubyforge_project = "deposit"

  s.add_dependency "ratom"
  s.add_dependency "rubyzip"
  s.add_dependency "activerecord"  # Would love to get rid of this

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
