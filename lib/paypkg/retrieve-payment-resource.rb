#################################
### Retrieve Payment Resource ###
#################################

class Paypkg
  # Use the payment_id to look up a payment.
  # @param payment_id [String] Required.
  # @return [json String] The same json string returned when
  #   the payment was orginally authorized.
  def retrieve_payment_resource(payment_id)
    call_paypal("/v1/payments/payment/#{payment_id}")
    return (@status.last=='200')
  end
end
