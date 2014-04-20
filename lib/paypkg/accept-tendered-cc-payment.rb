##########################################
### Payment Using Accepted Credit Card ###
##########################################

class Paypkg
  # This call is intended for use when the card is presented, but
  # not stored in the vault.
  # @param number [String] Required.
  # @param cvv2 [String] Optional.
  # @param first_name [String] Optional.
  # @param last_name [String] Optional.
  # @param expire_month [String] Required.
  # @param expire_year [String] Required.
  # @param amount [String] Required.
  # @param desc [String] Required.
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
end
