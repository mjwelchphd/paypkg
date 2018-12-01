############################
### Validate Credit Card ###
############################

class Paypkg
  # Validate a credit card by charging $0.01, then voiding the authorization.
  # The reason for doing this is to validate that an actual charge can be made
  # to the card. If you just attempt to store the card, and you get a valid
  # response, it just means that the card data had no syntactical errors,
  # not that you could ACTUALLY charge the card.
  # @param type [String] Required.
  # @param number [String] Required.
  # @param expire_month [Numeric] Required.
  # @param expire_year [Numeric] Required.
  # @param cvv2 [String] Required.
  # @param first_name [String] Required.
  # @param last_name [String] Required.
  # @param line1 [String] Required if any other address fields are present.
  # @param city [String] Required if any other address fields are present.
  # @param state [String] Required if any other address fields are present.
  # @param postal_code [String] Required if any other address fields are present.
  # @param country_code [String] Required if any other address fields are present.
  def validate_credit_card(type, number, expire_month, expire_year, cvv2, \
    first_name, last_name, line1, city, state, postal_code, country_code)
    data = ""
    data << "{
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
              'last_name':'#{last_name}',"
              if (!line1.empty?) || (!city.empty?) || (!state.empty?) || (!postal_code.empty?) || (!country_code.empty?)
              data << "              'billing_address':{
                'line1':'#{line1}',
                'city':'#{city}',
                'state':'#{state}',
                'postal_code':'#{postal_code}',
                'country_code':'#{country_code}'
              }"
              end
          data << "            }
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
    }"
    call_paypal("/v1/payments/payment", data)
    if (@status.last=='201') && (@hash.last[:state]=='approved')
      link = @hash.last[:transactions][0][:related_resources][0][:authorization][:links].select{|link| link[:rel]=='void'}
      endpoint = link[0][:href][@uri_base.length..-1] # remove the uri_base from the beginning of the link
      call_paypal(endpoint, nil, :method => :post, :reset => :no)
      return true if (@status.last=='200') && (@hash.last[:state]=='voided')
    end
    return false
  end
end
