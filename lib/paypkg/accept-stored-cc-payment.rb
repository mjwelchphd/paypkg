########################################
### Payment Using Stored Credit Card ###
########################################

class Paypkg
  # This method is intended for use when you want to charge
  # a card stored in the vault.
  # @param card_id [String] Required.
  # @param amount [Numeric] Required.
  # @param desc [String] Required.
  # @param email [String] Required.
  # @param payer_id [String] Required.
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
end
