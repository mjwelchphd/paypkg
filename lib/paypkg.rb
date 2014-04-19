require "net/http"
require "yaml"

class NilClass
  def empty?
    true
  end
end

class Paypkg

  VERSION = '0.1.0'

  attr_reader :json, :hash, :status, :mode, :link

private

  def initialize(session=nil)
    @session = if session then session else {} end
    @session[:paypal_authorization] ||= {}
    @session[:paypal_authorization][:expires_after] ||= Time.now-6
    @session[:paypal_authorization][:access_token] ||= ""
    env = Rails.env
    @mode = env.to_sym
    @credentials = YAML.load_file("#{Rails.root.to_path}/config/paypkg.yml")[env]
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
  end

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

  def call_paypal(endpoint, data=nil, options={reset: :yes, method: :get})
    set_access_token
    options = {:reset => :yes, :method => :get}.merge(options)
    if options[:reset]==:yes
      @json = []
      @hash = []
      @status = []
    end
    case
      when options[:method]==:delete
        request = Net::HTTP::Delete.new(endpoint)
      when options[:method]==:post || data # a json string
        request = Net::HTTP::Post.new(endpoint)
      when options[:method]==:get
        request = Net::HTTP::Get.new(endpoint)
    end
    request.add_field("Content-Type","application/json")
    request.add_field("Authorization", "Bearer #{@access_token}")
    request.body = data.gsub("'",'"') if data
    response = @http.request(request)
    response.body = nil if response.body.empty?
    @json << response.body
    @hash << if response.body then JSON.parse(response.body, :symbolize_names=>true) else nil end
    @status << response.code
  end

######################
### CURRENCY CODES ###
######################

  PAYPAL_CURRENCIES = {
    "Australian dollar" => "AUD",
    "Brazilian real" => "BRL",
    "Canadian dollar" => "CAD",
    "Czech koruna" => "CZK",
    "Danish krone" => "DKK",
    "Euro" => "EUR",
    "Hong Kong dollar" => "HKD",
    "Hungarian forint" => "HUF",
    "Israeli new shekel" => "ILS",
    "Japanese yen" => "JPY",
    "Malaysian ringgit" => "MYR",
    "Mexican peso" => "MXN",
    "New Taiwan dollar" => "TWD",
    "New Zealand dollar" => "NZD",
    "Norwegian krone" => "NOK",
    "Philippine peso" => "PHP",
    "Polish złoty" => "PLN",
    "Pound sterling" => "GBP",
    "Singapore dollar" => "SGD",
    "Swedish krona" => "SEK",
    "Swiss franc" => "CHF",
    "Thai baht" => "THB",
    "Turkish lira" => "TRY",
    "United States dollar" => "USD"
   }

######################
### LANGUAGE CODES ###
######################

  PAYPAL_LANGUAGES = [
    "da_DK",
    "de_DE",
    "en_AU",
    "en_GB",
    "en_US",
    "es_ES",
    "es_XC",
    "fr_CA",
    "fr_FR",
    "fr_XC",
    "he_IL",
    "id_ID",
    "it_IT",
    "ja_JP",
    "nl_NL",
    "no_NO",
    "pl_PL",
    "pt_BR",
    "pt_PT",
    "ru_RU",
    "sv_SE",
    "th_TH",
    "tr_TR",
    "zh_CN",
    "zh_HK",
    "zh_TW",
    "zh_XC"
  ]

#####################
### COUNTRY CODES ###
#####################

  PAYPAL_COUNTRIES = {
    "ALAND ISLANDS" => "AX",
    "ALBANIA" => "AL",
    "ALGERIA" => "DZ",
    "AMERICAN SAMOA" => "AS",
    "ANDORRA" => "AD",
    "ANGOLA" => "AO",
    "ANGUILLA" => "AI",
    "ANTARCTICA" => "AQ",
    "ANTIGUA AND BARBUDA" => "AG",
    "ARGENTINA" => "AR",
    "ARMENIA" => "AM",
    "ARUBA" => "AW",
    "AUSTRALIA" => "AU",
    "AUSTRIA" => "AT",
    "AZERBAIJAN" => "AZ",
    "BAHAMAS" => "BS",
    "BAHRAIN" => "BH",
    "BANGLADESH" => "BD",
    "BARBADOS" => "BB",
    "BELGIUM" => "BE",
    "BELIZE" => "BZ",
    "BENIN" => "BJ",
    "BERMUDA" => "BM",
    "BHUTAN" => "BT",
    "BOLIVIA" => "BO",
    "BOSNIA-HERZEGOVINA" => "BA",
    "BOTSWANA" => "BW",
    "BOUVET ISLAND" => "BV",
    "BRAZIL" => "BR",
    "BRITISH INDIAN OCEAN TERRITORY" => "IO",
    "BRUNEI DARUSSALAM" => "BN",
    "BULGARIA" => "BG",
    "BURKINA FASO" => "BF",
    "BURUNDI" => "BI",
    "CAMBODIA" => "KH",
    "CANADA" => "CA",
    "CAPE VERDE" => "CV",
    "CAYMAN ISLANDS" => "KY",
    "CENTRAL AFRICAN REPUBLIC" => "CF",
    "CHAD" => "TD",
    "CHILE" => "CL",
    "CHINA" => "CN (For domestic Chinese bank transactions only)",
    "CHRISTMAS ISLAND" => "CX",
    "COCOS (KEELING) ISLANDS" => "CC",
    "COLOMBIA" => "CO",
    "COMOROS" => "KM",
    "DEMOCRATIC REPUBLIC OF CONGO" => "CD",
    "CONGO" => "CG",
    "COOK ISLANDS" => "CK",
    "COSTA RICA" => "CR",
    "CROATIA" => "HR",
    "CYPRUS" => "CY",
    "CZECH REPUBLIC" => "CZ",
    "DENMARK" => "DK",
    "DJIBOUTI" => "DJ",
    "DOMINICA" => "DM",
    "DOMINICAN REPUBLIC" => "DO",
    "ECUADOR" => "EC",
    "EGYPT" => "EG",
    "EL SALVADOR" => "SV",
    "ERITERIA" => "ER",
    "ESTONIA" => "EE",
    "ETHIOPIA" => "ET",
    "FALKLAND ISLANDS (MALVINAS)" => "FK",
    "FAROE ISLANDS" => "FO",
    "FIJI" => "FJ",
    "FINLAND" => "FI",
    "FRANCE" => "FR",
    "FRENCH GUIANA" => "GF",
    "FRENCH POLYNESIA" => "PF",
    "FRENCH SOUTHERN TERRITORIES" => "TF",
    "GABON" => "GA",
    "GAMBIA" => "GM",
    "GEORGIA" => "GE",
    "GERMANY" => "DE",
    "GHANA" => "GH",
    "GIBRALTAR" => "GI",
    "GREECE" => "GR",
    "GREENLAND" => "GL",
    "GRENADA" => "GD",
    "GUADELOUPE" => "GP",
    "GUAM" => "GU",
    "GUATEMALA" => "GT",
    "GUERNSEY" => "GG",
    "GUINEA" => "GN",
    "GUINEA BISSAU" => "GW",
    "GUYANA" => "GY",
    "HEARD ISLAND AND MCDONALD ISLANDS" => "HM",
    "HOLY SEE (VATICAN CITY STATE)" => "VA",
    "HONDURAS" => "HN",
    "HONG KONG" => "HK",
    "HUNGARY" => "HU",
    "ICELAND" => "IS",
    "INDIA" => "IN",
    "INDONESIA" => "ID",
    "IRELAND" => "IE",
    "ISLE OF MAN" => "IM",
    "ISRAEL" => "IL",
    "ITALY" => "IT",
    "JAMAICA" => "JM",
    "JAPAN" => "JP",
    "JERSEY" => "JE",
    "JORDAN" => "JO",
    "KAZAKHSTAN" => "KZ",
    "KENYA" => "KE",
    "KIRIBATI" => "KI",
    "KOREA, REPUBLIC OF" => "KR",
    "KUWAIT" => "KW",
    "KYRGYZSTAN" => "KG",
    "LAOS" => "LA",
    "LATVIA" => "LV",
    "LESOTHO" => "LS",
    "LIECHTENSTEIN" => "LI",
    "LITHUANIA" => "LT",
    "LUXEMBOURG" => "LU",
    "MACAO" => "MO",
    "MACEDONIA" => "MK",
    "MADAGASCAR" => "MG",
    "MALAWI" => "MW",
    "MALAYSIA" => "MY",
    "MALDIVES" => "MV",
    "MALI" => "ML",
    "MALTA" => "MT",
    "MARSHALL ISLANDS" => "MH",
    "MARTINIQUE" => "MQ",
    "MAURITANIA" => "MR",
    "MAURITIUS" => "MU",
    "MAYOTTE" => "YT",
    "MEXICO" => "MX",
    "MICRONESIA, FEDERATED STATES OF" => "FM",
    "MOLDOVA, REPUBLIC OF" => "MD",
    "MONACO" => "MC",
    "MONGOLIA" => "MN",
    "MONTENEGRO" => "ME",
    "MONTSERRAT" => "MS",
    "MOROCCO" => "MA",
    "MOZAMBIQUE" => "MZ",
    "NAMIBIA" => "NA",
    "NAURU" => "NR",
    "NEPAL" => "NP",
    "NETHERLANDS" => "NL",
    "NETHERLANDS ANTILLES" => "AN",
    "NEW CALEDONIA" => "NC",
    "NEW ZEALAND" => "NZ",
    "NICARAGUA" => "NI",
    "NIGER" => "NE",
    "NIUE" => "NU",
    "NORFOLK ISLAND" => "NF",
    "NORTHERN MARIANA ISLANDS" => "MP",
    "NORWAY" => "NO",
    "OMAN" => "OM",
    "PALAU" => "PW",
    "PALESTINE" => "PS",
    "PANAMA" => "PA",
    "PARAGUAY" => "PY",
    "PAPUA NEW GUINEA" => "PG",
    "PERU" => "PE",
    "PHILIPPINES" => "PH",
    "PITCAIRN" => "PN",
    "POLAND" => "PL",
    "PORTUGAL" => "PT",
    "PUERTO RICO" => "PR",
    "QATAR" => "QA",
    "REUNION" => "RE",
    "ROMANIA" => "RO",
    "REPUBLIC OF SERBIA" => "RS",
    "RUSSIAN FEDERATION" => "RU",
    "RWANDA" => "RW",
    "SAINT HELENA" => "SH",
    "SAINT KITTS AND NEVIS" => "KN",
    "SAINT LUCIA" => "LC",
    "SAINT PIERRE AND MIQUELON" => "PM",
    "SAINT VINCENT AND THE GRENADINES" => "VC",
    "SAMOA" => "WS",
    "SAN MARINO" => "SM",
    "SAO TOME AND PRINCIPE" => "ST",
    "SAUDI ARABIA" => "SA",
    "SENEGAL" => "SN",
    "SEYCHELLES" => "SC",
    "SIERRA LEONE" => "SL",
    "SINGAPORE" => "SG",
    "SLOVAKIA" => "SK",
    "SLOVENIA" => "SI",
    "SOLOMON ISLANDS" => "SB",
    "SOMALIA" => "SO",
    "SOUTH AFRICA" => "ZA",
    "SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS" => "GS",
    "SPAIN" => "ES",
    "SRI LANKA" => "LK",
    "SURINAME" => "SR",
    "SVALBARD AND JAN MAYEN" => "SJ",
    "SWAZILAND" => "SZ",
    "SWEDEN" => "SE",
    "SWITZERLAND" => "CH",
    "TAIWAN, PROVINCE OF CHINA" => "TW",
    "TAJIKISTAN" => "TJ",
    "TANZANIA, UNITED REPUBLIC OF" => "TZ",
    "THAILAND" => "TH",
    "TIMOR-LESTE" => "TL",
    "TOGO" => "TG",
    "TOKELAU" => "TK",
    "TONGA" => "TO",
    "TRINIDAD AND TOBAGO" => "TT",
    "TUNISIA" => "TN",
    "TURKEY" => "TR",
    "TURKMENISTAN" => "TM",
    "TURKS AND CAICOS ISLANDS" => "TC",
    "TUVALU" => "TV",
    "UGANDA" => "UG",
    "UKRAINE" => "UA",
    "UNITED ARAB EMIRATES" => "AE",
    "UNITED KINGDOM" => "GB",
    "UNITED STATES" => "US",
    "UNITED STATES MINOR OUTLYING ISLANDS" => "UM",
    "URUGUAY" => "UY",
    "UZBEKISTAN" => "UZ",
    "VANUATU" => "VU",
    "VENEZUELA" => "VE",
    "VIETNAM" => "VN",
    "VIRGIN ISLANDS, BRITISH" => "VG",
    "VIRGIN ISLANDS, U.S." => "VI",
    "WALLIS AND FUTUNA" => "WF",
    "WESTERN SAHARA" => "EH",
    "YEMEN" => "YE",
    "ZAMBIA" => "ZM"
  }

############################
### Validate Credit Card ###
############################

  def validate_credit_card(type, number, expire_month, expire_year, cvv2, \
    first_name, last_name, line1, city, state, postal_code, country_code)
    call_paypal("/v1/payments/payment", "{
      'intent':'authorize',
      'payer':{
        'payment_method':'credit_card',
        'funding_instruments':[
          {
            'credit_card':{
              'number':'#{number}',
              'type':'#{type}',
              'expire_month':#{expire_month},
              'expire_year':#{expire_year},
              'cvv2':'#{cvv2}',
              'first_name':'#{first_name}',
              'last_name':'#{last_name}',
              'billing_address':{
                'line1':'#{line1}',
                'city':'#{city}',
                'state':'#{state}',
                'postal_code':'#{postal_code}',
                'country_code':'#{country_code}'
              }
            }
          }
        ]
      },
      'transactions':[
        {
          'amount':{
            'total':0.01,
            'currency':'USD'
          },
          'description':'This is a validation transaction.'
        }
      ]
    }")
    if (@status.last=='201') && (@hash.last[:state]=='approved')
      link = @hash.last[:transactions][0][:related_resources][0][:authorization][:links].select{|link| link[:rel]=='void'}
      call_paypal(link[0][:href], nil, :method => :post, :reset => :no)
      return true if (@status.last=='200') && (@hash.last[:state]=='voided')
    end
    return false
  end

#########################
### Store Credit Card ###
#########################

  def store_credit_card(type, number, expire_month, expire_year, cvv2, first_name,
    last_name, line1, line2, city, state, postal_code, country_code, payer_id)
    json = "{
      'payer_id':'#{payer_id}',
      'type':'#{type}',
      'number':'#{number}',
      'expire_month':'#{expire_month}',
      'expire_year':'#{expire_year}',
      'cvv2':'#{cvv2}',
      'first_name':'#{first_name}',
      'last_name':'#{last_name}',
      'billing_address':{
        'line1':'#{line1}',\n"
    json << " 'line2':'#{line2}',\n" if line2
    json << " 'city':'#{city}',
        'state':'#{state}',
        'postal_code':'#{postal_code}',
        'country_code':'#{country_code}'
      }
    }"
    call_paypal("/v1/vault/credit-card", json)
    return (@status.last=='201') && (@hash.last[:state]=='ok')
  end

############################
### Retrieve Credit Card ###
############################

  def retrieve_credit_card(vault_id)
    call_paypal("/v1/vault/credit-card/#{vault_id}")
    return (@status.last=='200') && (@hash.last[:state]=='ok')
  end

##########################
### Delete Credit Card ###
##########################

  def delete_credit_card(vault_id)
    call_paypal("/v1/vault/credit-card/#{vault_id}", nil, :method => :delete)
    return (@status.last=='204') && (@hash.last==nil)
  end

##########################################
### Payment Using Accepted Credit Card ###
##########################################

  def accept_tendered_cc_payment(type, number, expire_month, expire_year, cvv2, first_name,
    last_name, amount, desc)
    formatted_amount = "%0.2f"%amount
    json = "{
      'intent':'sale',
      'payer':{
        'payment_method':'credit_card',
        'funding_instruments':[
          {
            'credit_card':{
              'type':'#{type}',
              'number':'#{number}',"
    json << " 'cvv2':'#{cvv2}'," if cvv2
    json << " 'first_name':'#{first_name}'," if first_name
    json << " 'last_name':'#{last_name}'," if last_name
    json << " 'expire_month':'#{expire_month}',
              'expire_year':'#{expire_year}'
            }
          }
        ]
      },
      'transactions':[
        {
          'amount':{
            'total':'#{formatted_amount}',
            'currency':'USD'
          },
          'description':'#{desc}'
        }
      ]
    }"
    call_paypal("/v1/payments/payment", json)
    return (@status.last=='201') && (@hash.last[:state]=='approved')
  end

########################################
### Payment Using Stored Credit Card ###
########################################

  def accept_stored_cc_payment(card_id, amount, desc, email, payer_id)
    formatted_amount = "%0.2f"%amount
    call_paypal("/v1/payments/payment", "{
      'intent':'sale',
      'payer':{
        'payment_method':'credit_card',
        'payer_info':{
          'email':'#{email}'
        },
        'funding_instruments':[
          {
            'credit_card_token':{
              'credit_card_id':'#{card_id}',
              'payer_id':'#{payer_id}'
            }
          }
        ]
      },
      'transactions':[
        {
          'amount':{
            'total':'#{formatted_amount}',
            'currency':'USD'
          },
          'description':'#{desc}'
        }
      ]
    }")
    return (@status.last=='201') && (@hash.last[:state]=='approved')
  end

##############################
### Payment Through PayPal ###
##############################

  def accept_pp_payment(amount, desc, approved_url, cancelled_url, payer_id)
    set_access_token # we need this here to set the @website
    formatted_amount = "%0.2f"%amount
    json, status = call_paypal("/v1/payments/payment", "{
      'intent':'sale',
      'redirect_urls':{
        'return_url':'#{@website}/#{approved_url}/',
        'cancel_url':'#{@website}/#{cancelled_url}/'
      },
      'payer':{
        'payment_method':'paypal'
      },
      'transactions':[
        {
          'amount':{
            'total':'#{formatted_amount}',
            'currency':'USD'
          },
          'description':'#{desc}'
        }
      ]
    }")
    if (@status.last=='201') && (@hash.last[:state]=='created')
      @session[:payment_id] = @hash.last[:id]
      @link = @hash.last[:links].select{|link| link[:rel]=='approval_url'}[0][:href]
      return true
    else
      return false
    end
  end

  # this is executed by the code at the 'accepted' url
  def execute_payment(payer_id, payment_id)
    call_paypal("/v1/payments/payment/#{payment_id}/execute/", "{
      'payer_id' : '#{payer_id}'
    }")
    return (@status.last=='200') && (@hash.last[:state]=='approved')
  end

#################################
### Retrieve Sale Transaction ###
#################################

  def retrieve_sale_transaction(sale_id)
    call_paypal("/v1/payments/sale/#{sale_id}")
    return (@status.last=='200') && (['pending', 'completed', 'refunded', 'partially_refunded'].index(@hash.last[:state])>0)
  end

###############################################
### Full or Partial Refund Previous Payment ###
###############################################

  def refund_sale(sale_id,amount)
    formatted_amount = "%0.2f"%amount
    call_paypal("/v1/payments/sale/#{sale_id}/refund", "{
      'amount': {
        'total': #{formatted_amount},
        'currency': 'USD'
      }
    }")
    return (@status.last=='201') && (@hash.last[:state]=='completed')
  end

###################################
### Retrieve Refund Transaction ###
###################################

  def retrieve_refund_transaction(refund_id)
    call_paypal("/v1/payments/refund/#{refund_id}")
    return (@status.last=='200') && (['pending', 'completed', 'refunded', 'partially_refunded'].index(@hash.last[:state])>0)
  end

end
