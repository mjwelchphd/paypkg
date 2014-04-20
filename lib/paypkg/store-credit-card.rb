#########################
### Store Credit Card ###
#########################

class Paypkg
  # Store a credit card on the PalPal servers (in the vault, as the refer to it).
  # A card so stored can be used later to make charges, as long as the expire
  # date has not elapsed. Once the expire date elapses, eventually PayPal
  # will automatically remove the card. The card vault_id will be returned
  # from this call: you must save it in your database.
  # @param type [String] Required.
  # @param number [String] Required.
  # @param expire_month [Numeric] Required.
  # @param expire_year [Numeric] Required.
  # @param cvv2 [String] Required.
  # @param first_name [String] Required.
  # @param last_name [String] Required.
  # @param line1 [String] Required.
  # @param line2 [String] Optional. To omit this parameter, use nil.
  # @param city [String] Required.
  # @param state [String] Required.
  # @param postal_code [String] Required.
  # @param country_code [String] Required.
  # @return [String} The vault_id: you must save this in your database!
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
end
