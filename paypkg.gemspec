require_relative File.dirname(__FILE__) + '/lib/paypkg/version'
include Version
Gem::Specification.new do |s|
  s.name          = 'paypkg'
  # when changing version, also change the lib/paypkg.rb
  s.version       = VERSION
  s.date          = '2014-04-22'
  s.summary       = 'Simple PayPal Connection for Ruby'
  s.description   = "This gem uses Net::HTTP to communicate with the PayPal servers. It has calls for the most common PayPal functions to simplify using PayPal in a Ruby application."
  s.authors       = ["Michael J. Welch, Ph.D."]
  s.email         = 'rubygems@czarmail.com'
  s.files         = Dir.glob(["paypkg.gemspec", "config/paypkg.yml", "CHANGELOG.md", "README.md", "README.html", "lib/paypkg.rb", "lib/paypkg/*", "test/*", "test/paypkg_test/*" ])
  s.require_paths = ["lib"]
  s.homepage      = 'http://rubygems.org/gems/paypkg'
  s.license       = 'MIT'
end
