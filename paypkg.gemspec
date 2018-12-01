require_relative File.dirname(__FILE__) + '/lib/paypkg/version'
include Version
Gem::Specification.new do |s|
  s.name          = 'paypkg'
  s.version       = VERSION
  s.date          = MODIFIED
  s.summary       = 'Simple PayPal Connection for Ruby'
  s.description   = "This gem uses Net::HTTP to communicate with the PayPal servers. It has calls for the most common PayPal functions to simplify using PayPal in a Ruby application. I developed this package as a way to call PayPal's REST API with greater transparancy than the paypal-sdk-rest gem has, making development easier. This package can be easily extended by simply adding additional methods (as files) to the lib/paypkg folder. Contributions welcome."
  s.authors       = ["Michael J. Welch, Ph.D."]
  s.email         = 'mjwelchphd@gmail.com'
  s.files         = Dir.glob(["paypkg.gemspec", "config/paypkg.yml", "CHANGELOG.md", "README.md", "README.html", "lib/paypkg.rb", "lib/paypkg/*", "test/*", "test/paypkg_test/*" ])
  s.require_paths = ["lib"]
  s.homepage      = 'http://rubygems.org/gems/paypkg'
  s.license       = 'MIT'
end
