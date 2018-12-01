#! /usr/bin/ruby

require 'rack'
require 'rack/session/pool'
require 'sequel'

require 'pretty_inspect'

Log = File::open('log/app.log','a')     # use the same log as Rack uses

Sequel.extension :inflector # http://sequel.jeremyevans.net/rdoc-plugins/classes/String.html
# camelize, humanize, pluralize, singularize, tableize, titleize, to_date, to_datetime, to_time, underscore

class BigDecimal
  def inspect
    "%0.2f"%self
  end
end

class Application
  attr_accessor :path, :routing_map, :env

  def initialize
    @routing_map = {}                       # the route=>controller map
    @path = File.absolute_path('.')         # used to do 'absolute' requires

    @env = ENV['MODE']                      # 'development' or 'production'
    $app = self                             # just a pointer to the application object
#    require "#{$app.path}/models/init"      # do this first: scaffolding needs DB
    require "#{$app.path}/helpers/init"     # load all the helpers
    require "#{$app.path}/controllers/init" # get all the controllers and map them
  end

  def call(env)
    # save the request, and create a response
    request = Rack::Request.new(env)
    response = Rack::Response.new

    # search the map created when the controllers were loaded
    parts = request.path_info.downcase.split('/')
    parts.delete_at(0) if parts[0]==""

    # calculate the routing for this request

#puts "--> *10* parts.size=>#{parts.size} parts=>#{parts.inspect}"
    case
    when parts.size==0
      controller = MainController
      method_name = 'index'
    when parts.size==1
      controller = $app.routing_map["/#{parts[0]}"]
      if controller
        method_name = 'index'
      else
        controller = MainController
        method_name = parts[0]
      end
    else
      method_name = parts.delete_at(-1)
      controller = $app.routing_map["/#{parts.join('/')}"]
    end
    method = method_name.to_sym
#puts "--> *11* controller=>#{controller.inspect}"
#puts "--> *12* method_name=>#{method_name.inspect}"

    # log the routing on the console
    msg = "Routing: request.path_info=>#{request.path_info.inspect}, (#{parts.size}) part(s)=>#{parts.inspect}, method_name=>#{method_name.inspect}, controller=>#{controller.inspect}, method=>#{method.inspect}"
    Log.write("#{msg}\n")
    Log.flush

    # try to route it
    if controller
      # we found a valid controller, so get an instance
      obj = controller.new
      begin
        file, line = obj.method(method).source_location
        # reload controller in 'dev' mode
        if @env=='development' && File::exists?(file)
          Log.write("Reloading #{file.inspect} in 'development' mode.\n")
          load file
        end

        # the method exists, so call it
        request[:route] = "/#{parts.join('/')}"
        if !request.session.has_key?(:home_url)
          request.session.delete(:id)
          request.session.delete(:username)
          request.session.delete(:first)
          request.session[:home_url] = '/'
        end
        obj.request = request
        obj.response = response
        obj.params = {}
        request.params.each { |k,v| obj.params[k.to_sym] = v }

        # check the authorization here -- I had it in the Controller class, but
        # the scaffolding can't access the session variable, so I had to move it here --
        # #method raises a NameError (undocumented) and also returns true false
        begin
          authorized = obj.authorize(method)
        rescue NameError=>e
          if request.session[:id].nil?
            authorized = false
          else
            p = Person.select(:role).where(:id=>request.session[:id]).first
            c = Role.select(:id).where(:role_name=>p.role, :controller_name=>obj.class.name)
            authorized = !c.first.nil?
          end
        end

        if authorized
          begin
            # run the 'before', if any
            obj.before(request.path_info, controller, method)
            # run the method and get a response
            out = obj.send(method)
            response.write(out)
            # run the 'after', if any
            obj.after(request.path_info, controller, method, out)
          rescue => e
            # this is the "rescue of last resort"
            Log.write("*** Rescue of Last Resort ***\n")
            Log.write(e.inspect)
            e.backtrace.each { |line| Log.write("#{line}\n") }
            Log.flush
            response.write("Rescue of last resort: #{e} (see log)")
response.write(e.inspect) # TODO!
e.backtrace.each { |line| response.write("#{line}\n") }
          end
          return response.finish
        else
          message = "Sorry, but you're not authorized to make that request"
        end
      rescue NameError => e
puts "--> *20* e=>#{e.inspect}"
e.backtrace.each { |line| puts("#{line}\n") }
        message = "There is no method <i>#{method}</i> for controller <i>#{obj.class.name}</i>"
        message << "\n"
        e.backtrace.each { |line| message << "#{line}\n" }
      end
    else
      message = "There is no controller for that request"
    end

    # return the error message
    obj = MainController.new
    obj.request = request
    obj.response = response
    response.write(obj.send(:not_authorized, "<body><h3>#{message}.</h3></body>"))
    response.status = 404
    response.finish
  end

end
