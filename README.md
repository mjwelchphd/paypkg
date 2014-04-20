Copyright (c) 2014, Michael J. Welch, Ph.D. and Contributors. All Rights Reserved.
Email: rubygems@czarmail.com

This project is licenced under the [MIT License](LICENSE.md).


###############
### Install ###
###############

To install this gem, use:
  gem install paypkg

I also recommend pretty_inspect, which I use in my example below
and in the test page:
  gem install pretty_inspect
  
Add the following routes to your route file:
  get   'paypkg_test/test1'           => 'paypkg_test#test1'
  get   'paypkg_test/test2'           => 'paypkg_test#test2'
  get   'paypkg_test/approved'        => 'paypkg_test#approved'
  get   'paypkg_test/cancelled'       => 'paypkg_test#cancelled'

Copy the files in the gem's test folder to the app/controllers and app/views, as appropriate:


####################################
### Setup the Configuration File ###
####################################

This gem requires a config file in config/paypkg.yml in your
Rails project that looks like this:

--- begin config/paypkg.yml -----------------------------------------------
development:
  client_id: 'AZPi5hCY-0SoaLmignRs9XV6N4mvRS2TVKFDF2ni53alKL0iJTvtcy9BSR4D'
  secret: 'EDubEBAg_ZztC-_HlsW16IFZcxBIatFt7c0ILuxNTpWAVnvrsO9ywVxnHr7J'
  uri_base: 'https://api.sandbox.paypal.com'
  website: 'http://www.example.com:3000'

test:
  client_id: 'AZPi5hCY-0SoaLmignRs9XV6N4mvRS2TVKFDF2ni53alKL0iJTvtcy9BSR4D'
  secret: 'EDubEBAg_ZztC-_HlsW16IFZcxBIatFt7c0ILuxNTpWAVnvrsO9ywVxnHr7J'
  uri_base: 'https://api.sandbox.paypal.com'
  website: 'http://www.example.com:3000'

production:
  client_id: 'AVWiuBCE6_ps2zCh0Qaq0MaIbP8v2bjfFnKH5esYR9v6sNvu-MzVeWny3crM'
  secret: 'EKKoNhCgFn_0lmpUAxXir0ySN4cmaLzGugUmnkgZHR90Kg9Y_DFmJbI2H0Ee'
  uri_base: 'https://api.paypal.com'
  website: 'https://www.example.com'
--- end config/paypkg.yml -------------------------------------------------

See the sample in this gem under config/paypkg.yml.

You have to place your client_id and secret in the file in place of these,
and you have to replace the website with yours. Note that the production
website has https, not http. If your production website is not encrypted
with SSL, use http instead of https.


######################
### Testing in irb ###
######################

The Paypkg class can't see the session variable (because it's only visible
in ApplicationController classes), so to test this interactively, go into
your project and run "rails c" to start irb with a Rails environment, then
create a session variable, and create an instance. You can then run the
functions.

Why can't I just use irb? Because you need the Rails environment.
That's why the tests are supplied as a controller/views.


######################
### Using Bundler? ###
######################

If you're using bundler, you'll have to add 'paypkg' and 'pretty_inspect'
to your Gemfile, then do a 'bundler install' to be able to use them.


###############################
### An Example in "rails c" ###
###############################

To use the example, by the way, you'll have to put in a 'CARD-XXX...'
number of your own.

Here is an example:

devel@mail:~/czar$ rails c
Loading development environment (Rails 4.0.4)
irb(main):001:0> session = {}
=> {}
irb(main):002:0> pp = Paypkg.new session
=> #<Paypkg:0x000000049f5138 @session={:paypal_authorization=>{:expires_after=>2014-04-19 04:54:05 +0000,\
   :access_token=>"8PhJDJVg1mxxGUpSHj9RzzUxB0.sS0qiajx2Nxa1.Fg"}}, @mode=:development, 
   @credentials={"client_id"=>"AZPi5hCY-0SoaLsvRSni5mignR3a9XlKL2TVKFDFV6N4m20iJTvtcy9BSR4D", 
   "secret"=>"EDubEBAg_ZztC-_HlscxNTpWAVtFt7c0ILZW1BIaOnvrsux6IF9ywVxnHr7J",
   "uri_base"=>"https://api.sandbox.paypal.com", "website"=>"http://www.example.com:3000"},
   @website="http://www.example.com:3000", @uri_base="https://api.sandbox.paypal.com",
   @http=#<Net::HTTP api.sandbox.paypal.com:443 open=false>,
   @access_token="8PhJDJVg1mxxGUpSHj9RzzUxB0.sS0qiajx2Nxa1.Fg", @json=[], @hash=[], @status=[]>
irb(main):003:0> @ok = pp.retrieve_credit_card('CARD-22T35414AU135641UKLX6GPQ')
=> true
irb(main):004:0> puts pp.json
{"id":"CARD-22T35414AU135641UKLX6GPQ","state":"ok","payer_id":"admin","type":"visa",
 "number":"xxxxxxxxxxxx0331","expire_month":"11","expire_year":"2018","first_name":"Betsy",
 "last_name":"Buyer","billing_address":{"line1":"111 First Street",  "city":"Saratoga",
 "state":"CA","postal_code":"95070","country_code":"US"},
 "valid_until":"2017-02-02T00:00:00Z","create_time":"2014-02-03T18:43:10Z",
 "update_time":"2014-02-03T18:43:10Z",
 "links":[{"href":"https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ","rel":"self","method":"GET"},
 {"href":"https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ","rel":"delete","method":"DELETE"},
 {"href":"https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ","rel":"patch","method":"PATCH"}]}
=> nil
irb(main):005:0> puts pp.status
200
=> nil
irb(main):006:0> puts pp.mode
development
=> nil
irb(main):007:0> puts pp.hash
{:id=>"CARD-22T35414AU135641UKLX6GPQ", :state=>"ok", :payer_id=>"admin", :type=>"visa",
 :number=>"xxxxxxxxxxxx0331", :expire_month=>"11", :expire_year=>"2018", :first_name=>"Betsy",
 :last_name=>"Buyer", :billing_address=>{:line1=>"111 First Street", :city=>"Saratoga",
 :state=>"CA", :postal_code=>"95070", :country_code=>"US"},
 :valid_until=>"2017-02-02T00:00:00Z", :create_time=>"2014-02-03T18:43:10Z",
 :update_time=>"2014-02-03T18:43:10Z",
 :links=>[{:href=>"https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ", :rel=>"self", :method=>"GET"},
 {:href=>"https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ", :rel=>"delete", :method=>"DELETE"},
 {:href=>"https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ", :rel=>"patch", :method=>"PATCH"}]}
=> nil
irb(main):008:0> puts pp.hash.pretty_inspect
[
  {
    :id => "CARD-22T35414AU135641UKLX6GPQ",
    :state => "ok",
    :payer_id => "admin",
    :type => "visa",
    :number => "xxxxxxxxxxxx0331",
    :expire_month => "11",
    :expire_year => "2018",
    :first_name => "Betsy",
    :last_name => "Buyer",
    :billing_address => {
      :line1 => "111 First Street",
      :city => "Saratoga",
      :state => "CA",
      :postal_code => "95070",
      :country_code => "US"
    },
    :valid_until => "2017-02-02T00:00:00Z",
    :create_time => "2014-02-03T18:43:10Z",
    :update_time => "2014-02-03T18:43:10Z",
    :links => [
      {
        :href => "https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ",
        :rel => "self",
        :method => "GET"
      },
      {
        :href => "https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ",
        :rel => "delete",
        :method => "DELETE"
      },
      {
        :href => "https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ",
        :rel => "patch",
        :method => "PATCH"
      }
    ]
  }
]
=> nil
irb(main):009:0> r=pp.response
=> #<PaypkgResponse:0x000000045fe7a0 @id="CARD-22T35414AU135641UKLX6GPQ", @state="ok", @payer_id="admin", @type="visa", @number="xxxxxxxxxxxx0331", @expire_month="11", @expire_year="2018", @first_name="Betsy", @last_name="Buyer", @billing_address=#<PaypkgResponse:0x000000045fd170 @state="CA", @line1="111 First Street", @city="Saratoga", @postal_code="95070", @country_code="US">, @valid_until="2017-02-02T00:00:00Z", @create_time="2014-02-03T18:43:10Z", @update_time="2014-02-03T18:43:10Z", @links=[#<PaypkgResponse:0x00000004603f20 @href="https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ", @rel="self", @method="GET">, #<PaypkgResponse:0x00000004603728 @href="https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ", @rel="delete", @method="DELETE">, #<PaypkgResponse:0x000000046030c0 @href="https://api.sandbox.paypal.com/v1/vault/credit-card/CARD-22T35414AU135641UKLX6GPQ", @rel="patch", @method="PATCH">]>
irb(main):010:0> r.billing_address.line1
=> "2945 Hampton Ave"
irb(main):009:0>


############################
### PaypkgResponse Class ###
############################

The class PaypkgResponse is used to objectize a response hash (or almost any
hash object). Free free to use it separately in other projects, if it works for you.

To get the PayPal response in an object format, after a successful call, use response = pp.response.
If you want this, for example:

  payment_data = pp.hash.last
  @amount = payment_data[:transactions][0][:related_resources][0][:sale][:amount][:total]

you would use this:

  payment_data = pp.response # this will convert pp.hash.last
  @amount = payment_data.transactions[0].related_resources[0].sale.amount.total

This is provided to be more compatible with views using ActiveRecord conventions.


###############
### Caveats ###
###############

Caveats:
  1. This class is designed to do the most common things most people want
     to do, but without much fuss.
  2. You can make your own calls to PayPal by creating a json data string
     and calling call_paypal. See the cURL commands in the documentation
     to see how the json should be configured. Look at the existing methods
     in lib/paypkg to see how they are structured. Just add yours to the
     lib/paypkg folder, and it will be available after the gem is
     reloaded. Refer to https://developer.paypal.com/webapps/developer/docs/api/
     for PayPal Restful calls.
  3. Be sure to look at the PaypkgTestController for information on how
     to use the calls in your appication.

