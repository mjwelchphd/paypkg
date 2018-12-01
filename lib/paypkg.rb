require "net/http"
require "json"

# @author Michael J. Welch, Ph.D.

# The PaypkgResponse class converts a standard hash to a nested class object...
# NOTE: The outside object MUST BE a hash
# For example:
#  e = PaypkgResponse.new({'x'=>7,'a'=>[{'f'=>1},{'g'=>2}]})
# yields:
#  <PaypkgResponse:0x00000004dc0e20 @x=7, @a=[#<PaypkgResponse:0x00000004dc0ce0 @f=1>, #<PaypkgResponse:0x00000004dc0bf0 @g=2>]>
# and can be accessed like the example below.
#
# @param hash [Hash] The hash to be converted into an object
# @example PaypkgResponse
#  puts e => #<Response:0x00000004dd3c50>
#  puts e.x => 7
#  puts e.a => [#<Response:0x00000004dd3b10>, #<Response:0x00000004dd39f8>]
#  puts e.a[0].f => 1
#  puts e.a[1].g => 2
class PaypkgResponse
  def initialize(hash)
    hash.each do |name, value|
      case
        when value.class==Array
          obj = []
          value.each { |item| obj << PaypkgResponse.new(item) }
          self.class.__send__(:attr_accessor, name)
          instance_variable_set("@#{name}", obj)
        when value.class==Hash
          self.class.__send__(:attr_accessor, name)
          instance_variable_set("@#{name}", PaypkgResponse.new(value))
        else
          self.class.__send__(:attr_accessor, name)
          instance_variable_set("@#{name}", value)
      end
    end
  end
end

class Paypkg

  include JSON

  attr_reader :json, :hash, :status, :mode, :link, :request

private

  # The initialize method reads the config file, calls PayPal for an access_token,
  # stores the access_token in the session, and initializes some variables
  # @param session [Hash] The session object from your ApplicationController subclass
  def initialize(session=nil, env=nil, path=nil)
    env = 'development' if env.nil?
    path = '.' if path.nil?
    @session = if session then session else {} end
    @session[:paypal_authorization] ||= {}
    @session[:paypal_authorization][:expires_after] ||= Time.now-6
    @session[:paypal_authorization][:access_token] ||= ""
    @mode = env.to_sym
    @credentials = YAML.load_file("#{path}/config/paypkg.yml")[env]
    @website = @credentials['website']
    @uri_base = @credentials['uri_base']
    uri = URI.parse(@uri_base)
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true
    #@http.set_debug_output $stderr #  <-- ONLY FOR DEBUG!
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    set_access_token
    @json = []
    @hash = []
    @status = []
    @request = []
  end

  # The set_access_token method is called before each PayPal request to validate
  # the access_token -- if the token is stale, a new one is obtained
  def set_access_token
    if (Time.now-5)>@session[:paypal_authorization][:expires_after]
      request = Net::HTTP::Post.new("/v1/oauth2/token")
      request.add_field("Accept","application/json")
      request.add_field("Accept-Language","en_US")
      request.basic_auth(@credentials['client_id'], @credentials['secret'])
      request.body = "grant_type=client_credentials"
      response = @http.request(request)
      if response.code!='200'
        @session[:paypal_authorization][:expires_after] = Time.now-1
        @session[:paypal_authorization][:access_token] = ""
        @access_token = nil
        raise Net::HTTPServerException.new("Unable to obtain access token from PayPal", response)
      else
        hash = JSON.parse(response.body, :symbolize_names=>true)
        @session[:paypal_authorization][:expires_after] = Time.now+hash[:expires_in]
        @session[:paypal_authorization][:access_token] = hash[:access_token]
        @access_token = @session[:paypal_authorization][:access_token]
      end
    else
      @access_token = @session[:paypal_authorization][:access_token]
    end
  end

public

  # The call_paypal method is used to call PayPal with a json string, and return the
  # response json string and HTTP exit code -- The json response, the response
  # converted into a hash, and the status code are all stored -- some calls (like
  # validate_credit_card) actually make two PayPal calls, so the json, hash,
  # and status are arrays
  #
  # @param endpoint [String] The PayPal endpoint depends on which service
  #   you're requesting -- required
  # @param data [json String] The "put" data, if any, in the form of a json string
  # @param reset [:yes or :no] If the json, hash, and status should be cleared, then :yes,
  #   or :no for the second PayPal call in a two call function
  # @param method [:get, :post, or :delete] The HTTP type
  # @example
  #  call_paypal("/v1/payments/payment/PAY-2BG385817G530460DKNDSITI/execute/", "{
  #    'payer_id' : 'EC-71588296U3330482A'
  #  }")
  # @return [json String] The json response from PayPal, if any
  # @return [Hash] The json String converted into a hash
  # @return [String] The HTTP status code
  def call_paypal(endpoint, data=nil, options={reset: :yes, method: :get})
    set_access_token
    options = {:reset => :yes, :method => :get}.merge(options)
    if options[:reset]==:yes
      @json = []
      @hash = []
      @status = []
      @request = []
    end
    case
      when options[:method]==:delete
        request = Net::HTTP::Delete.new(endpoint)
      when options[:method]==:post || data # a json string
        request = Net::HTTP::Post.new(endpoint)
      when options[:method]==:get
        request = Net::HTTP::Get.new(endpoint)
    end
    @request << data
    request.add_field("Content-Type","application/json")
    request.add_field("Authorization", "Bearer #{@access_token}")
    request.body = data.gsub("'",'"') if data
    response = @http.request(request)
    response.body = nil if response.body.empty?
    @json << response.body
    @hash << if response.body then JSON.parse(response.body, :symbolize_names=>true) else nil end
    @status << response.code
  end

  # This is a getter which is used to obtain the PaypkgResponse Object
  # from the hash
  # @return [PaypkgResponse Instance]
  def response
    if hash.last then PaypkgResponse.new(hash.last) else nil end
  end

  # This method collects the response data in such a way as to guarantee
  # valid Ruby stuctures will be generated, i.e., you won't get a
  # runtime error because of nil, etc.
  #
  # It produces 3 outputs:
  #  (1) A non-nil error hash
  #   {
  #     :name => "VALIDATION_ERROR",
  #     :details => [
  #       {
  #         :field => "payer.funding_instruments[0].credit_card.number",
  #         :issue => "Value is invalid"
  #       },
  #       {
  #         :field => "payer.funding_instruments[0].credit_card.number",
  #         :issue => "Number is crap"
  #       }
  #     ],
  #     :message => "Invalid request - see details",
  #     :information_link => "https://developer.paypal.com/webapps/developer/docs/api/#VALIDATION_ERROR",
  #     :debug_id => "88dcf0c1730bb"
  #   }
  #  (2) A non-nil response object
  #    <PaypkgResponse:0x00000001e60040 @name="VALIDATION_ERROR",
  #      @details=[
  #        <PaypkgResponse:0x00000001e73e10 @field="payer.funding_instruments[0].credit_card.number", @issue="Value is invalid">, \
  #        <PaypkgResponse:0x00000001e73988 @field="payer.funding_instruments[0].credit_card.number", @issue="Invalid card type"> \
  #      ],
  #     @message="Invalid request - see details", \
  #     @information_link="https://developer.paypal.com/webapps/developer/docs/api/#VALIDATION_ERROR", \
  #     @debug_id="88dcf0c1730bb"
  #    >
  #  (3) A non-nil details array
  #    [
  #      {
  #        :field => "payer.funding_instruments[0].credit_card.number",
  #        :issue => "Value is invalid"
  #      },
  #      {
  #        :field => "payer.funding_instruments[0].credit_card.number",
  #        :issue => "Number is crap"
  #      }
  #    ]
  def error_data
      conditioned_details = []
      if @hash.last
        conditioned_hash = @hash.last
        # sometimes there's details, sometimes not
        if conditioned_hash.has_key?(:details)
          # process errors
          conditioned_hash[:details].each do |detail|
            conditioned_details << detail
          end
        end
      else
        status = @status.last
        case status[0]
        when '4'
          name = "CLIENT ERROR"
          message = "The request sent to PayPal was invalid"
        when '5'
          name = "SERVER ERROR"
          message = "PayPay's servers had a problem"
        else
          name = "UNKNOWN ERROR"
          message = ""
        end
        conditioned_hash = {
            :name => name,
            :message => "%s. PayPal returned status code %s"%[message,status],
            :information_link => "https://developer.paypal.com/webapps/developer/docs/api",
            :debug_id => "0000000000000"
          }
      end
      conditioned_response = PaypkgResponse.new(conditioned_hash)
      return conditioned_hash, conditioned_response, conditioned_details
  end
end

# This require loop has to be after the Paypkg class.
# File.dirname(__FILE__) => the location of this file in
# the place where your system installed this gem.
Dir[File.dirname(__FILE__) + '/paypkg/*.rb'].each {|file| require(file) }

# This has to be after the above require loop because the
# Version module is one of the files being required.
class Paypkg
  include Version
end

