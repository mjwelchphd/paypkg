###############################################
### Full or Partial Refund Previous Payment ###
###############################################

class Paypkg
  # You can request a partial or full refund of a previous sale.
  # You CANNOT, however, refund more than the original sale.
  # If you need to do that, you'll have to do it manually
  # through your PalPal account.
  #
  # If you think you'll ever want to look up the refund,
  # you'll have to save the refund_id in your database.
  #
  # @param sale_id [String] Required.
  # @param amount [Numeric] Required.
  def refund_sale(sale_id, amount)
    formatted_amount = "%0.2f"%amount
    call_paypal("/v1/payments/sale/#{sale_id}/refund", "{
      'amount': {
        'total': #{formatted_amount},
        'currency': 'USD'
      }
    }")
    return (@status.last=='201') && (@hash.last[:state]=='completed')
  end
end
