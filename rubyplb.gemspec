# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rubyplb/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kow Kuroda", "Yoichiro Hasebe"]
  gem.email         = ["yohasebe@gmail.com"]
  gem.summary         = %q{Command line Pattern Lattice building tool written in Ruby}  
  gem.description     = %q{Command line Pattern Lattice building tool written in Ruby.}  
  gem.homepage        = "http://github.com/yohasebe/rubyplb"  

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rubyplb"
  gem.require_paths = ["lib"]
  gem.version       = Rubyplb::VERSION  
end
