Gem::Specification.new do |s|
  s.name          = 'paypkg'
  # when changing version, also change the lib/paypkg.rb
  s.version       = '0.1.0'
  s.date          = '2014-04-16'
  s.summary       = 'Simple PayPal Connection for Ruby'
  s.description   = "This gem uses Net::HTTP to communicate with the PayPal servers. It has calls for the most common PayPal functions to simplify using PayPal in a Ruby application."
  s.authors       = ["Michael J. Welch, Ph.D."]
  s.email         = 'rubygems@czarmail.com'
  s.files         = [ "lib/paypkg.rb" ]
  s.require_paths = ["lib"]
  s.homepage      = 'http://rubygems.org/gems/paypkg'
  s.license       = 'MIT'
end
