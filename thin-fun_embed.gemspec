# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thin/fun_embed/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sokolov Yura 'funny-falcon'"]
  gem.email         = ["funny.falcon@gmail.com"]
  gem.description   = %q{trim of Thin web server for embedding into eventmachined application}
  gem.summary       = "Subclass of EM::Connection which uses thin internals to do http request handling.\n"\
                      "It is intentionally not Rack server, but could be used to build some."

  gem.homepage      = "https://github.com/funny-falcon/thin-fun_embed"

  gem.files         = Dir["examples/*"] + Dir["lib/**/*.rb"] +
                      %w{Gemfile LICENSE Rakefile README.rdoc thin-fun_embed.gemspec}
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "thin-fun_embed"
  gem.require_paths = ["lib"]
  gem.version       = Thin::FunEmbed::VERSION

  gem.add_dependency 'thin', ['>= 1.4']
end
