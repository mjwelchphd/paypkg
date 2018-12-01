=begin
require 'sequel'
require 'demeler'
require 'erb'
require "#{$app.path}/constants"
require "#{$app.path}/helpers/database"

include DatabaseHelpers
include Constants
=end

class NilClass
  def strftime(pattern)
    ""
  end
  def empty?
    true
  end
end

class OwnershipError < StandardError
end

class Controller

  include Constants

  def initialize
    @request = nil
    @response = nil
    @params = nil
  end

  def self::map(route)
    $app.routing_map[route] = self.ancestors[0]
#puts "--> *10* #{$app.routing_map}"
#puts "--> *10* XXX=>#{XXX.inspect}"
  end

  # this is a 'do nothing' default 'before' method
  def before(path_info, controller, method)
  end

  # this is a 'do nothing' default 'after' method
  def after(path_info, controller, method, out)
  end

  def redirect_to(args)
    raise ArgumentError.new("'redirect_to' must have the form ':action=>href'") if !args.kind_of?(Hash) || !args.has_key?(:action)
    action = args.delete(:action)
    href = if action.kind_of?(Symbol) then "#{params[:route]}/#{action}" else String.new(action) end
    tmp = []
    args.each { |k,v| tmp << "#{k}=#{v}" }
    ( href << '?' << tmp.join('&') ) if !tmp.empty?
    @response.redirect(href)
  end

  def request
    @request
  end

  def request=(value)
    @request = value
  end

  def response
    @response
  end

  def response=(value)
    @response = value
  end

  def params
    @params
  end

  def params=(value)
    @params = value
  end

  def session
    @request.session
  end

  def render_view(content_file_name="views/params.erb", layout_file_name="views/layout.erb", menu_file_name="views/menu.erb")
    # figure out the path to the content file
    case
    when content_file_name.kind_of?(String)
      cfn = content_file_name
    when params[:route]=='/'
      cfn = "views/main/index.erb"
    when self.class==MainController
      cfn = "views/main/#{content_file_name}.erb".gsub("__","/")
    else
      cfn = "views#{params[:route]}/#{content_file_name}.erb"
    end

    # open and read the content file
    content = nil
    begin
      File::open(cfn, 'r') { |content_file| content = ERB.new(content_file.read).result(binding) }
    rescue => e
      response.write("ERB failed while processing #{cfn}: #{e}\n")
      e.backtrace.each { |line| response.write("#{line}\n") }
      return
    end

    # open and read the menu file (if any)
    menu = nil
    if menu_file_name
      mfn = if menu_file_name.kind_of?(Symbol) then "views/#{menu_file_name}.erb" else menu_file_name end
      begin
        File::open(mfn, 'r') { |menu_file| menu = ERB.new(menu_file.read).result(binding) }
      rescue => e
        response.write("ERB failed while processing #{mfn}: #{e}\n")
        e.backtrace.each { |line| response.write("#{line}\n") }
        return
      end
    end

    # open and read the layout file
    layout = nil
    if layout_file_name
      lfn = if layout_file_name.kind_of?(Symbol) then "views/#{layout_file_name}.erb" else layout_file_name end
      begin
        File::open(lfn, 'r') { |layout_file| layout = ERB.new(layout_file.read).result(binding) }
      rescue => e
        response.write("ERB failed while processing #{lfn}: #{e}\n")
        e.backtrace.each { |line| response.write("#{line}\n") }
        return
      end
    end
  end

  def render_text(content, layout_file_name="views/layout.erb", menu_file_name="views/menu.erb")
    # open and read the menu file (if any)
    menu = nil
    if menu_file_name
      mfn = if menu_file_name.kind_of?(Symbol) then "views/#{menu_file_name}.erb" else menu_file_name end
      begin
        File::open(mfn, 'r') { |menu_file| menu = ERB.new(menu_file.read).result(binding) }
      rescue => e
        response.write("ERB failed while processing #{mfn}: #{e}\n")
        e.backtrace.each { |line| response.write("#{line}\n") }
        return
      end
    end

    # open and read the menu file (if any)
    menu = nil
    if menu_file_name
      mfn = if menu_file_name.kind_of?(Symbol) then "views/#{menu_file_name}.erb" else menu_file_name end
      begin
        File::open(mfn, 'r') { |menu_file| menu = ERB.new(menu_file.read).result(binding) }
      rescue => e
        response.write("ERB failed while processing #{mfn}: #{e}\n")
        e.backtrace.each { |line| response.write("#{line}\n") }
        return
      end
    end

    # open and read the layout file
    layout = nil
    lfn = if layout_file_name.kind_of?(Symbol) then "views/#{layout_file_name}.erb" else layout_file_name end
    begin
      File::open(lfn, 'r') { |layout_file| layout = ERB.new(layout_file.read).result(binding) }
    rescue => e
      response.write("ERB failed while processing #{lfn}: #{e}\n")
      e.backtrace.each { |line| response.write("#{line}\n") }
      return
    end
  end

  def not_authorized(message)
    render_text message
  end

  def user_option(name)
    rs = Option.where(:owner_id=>[0,session[:id]], :option_name=>name).reverse_order(:owner_id).first
    rs[:option_value]
  end

  def access_denied
    controller = params[:route][1..-1]
    session[controller.to_sym] = {}
    render_text(Demeler.build do
      h3 { "An object you tried to access in #{controller} is not yours: access denied." }
      alink("OK", :href=>:index)
      end)
  end

private

  # this method strips leading and trailing spaces from string
  # fields, and replaces empty string fields with nil (NULL)
  def set_fields_with_trim(rs, parms, fields, opts=nil)
    hash = {}
    parms.each do |k,v1|
      case
      when v1.nil?
        v2 = nil
      when v1.class==String
        # trim; if empty, replace with nil
        v2 = v1.strip
        v2 = nil if v2.empty?
      else
        v2 = v1
      end
      hash[k] = v2
    end
    rs.set_fields(hash, fields, opts)
  end

  # this method strips leading and trailing spaces from string
  # fields, and replaces empty string fields with nil (NULL)
  def set_fields_with_null(rs, hash, fields, opts=nil)
    hash.each do |k,v|
      row = @schema[k]
      if row
        if row[:type]==:string
          v = v.strip
          v = nil if row[:default].nil? && !v.nil? && v.empty?
          hash[k] = v
        end
      end
    end
    rs.set_fields(hash, fields, opts)
  end

end

# Require all controllers in the controllers folder
Dir.glob("#{$app.path}/controllers/*.rb").each do |controller|
#puts "--> *90* #{controller.inspect}"
  require(controller)
end
