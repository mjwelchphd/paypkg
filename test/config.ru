# TO RUN:
#  rackup --port 3000 --host ekgreaders.com

require 'rack'
require './app.rb'
require 'logger'

application = Application.new
logger = Logger.new('log/app.log','weekly')

use Rack::CommonLogger,    logger
use Rack::Static,          :urls => ["/css", "/images", "/javascript"], :root => "public"
use Rack::Session::Cookie, :key=>'rack.session',
                           :domain => 'ekgreaders.com',
                           :expire_after => 2592000,
                           :secret => 'Cocosaurus Rex',
                           :old_secret => 'Cocosaurus Rex'
use Rack::Session::Pool,   :domain => 'ekgreaders.com',
                           :expire_after => 2592000
run application
