###################################
### Retrieve Refund Transaction ###
###################################

class Paypkg
  # Use the refund_id to look up the refund.
  # @param refund_id [String] Required.
  # @return [json String] The same json string retured when
  #   the refund was orginally completed.
  def retrieve_refund_transaction(refund_id)
    call_paypal("/v1/payments/refund/#{refund_id}")
    return (@status.last=='200') && (['pending', 'completed', 'refunded', 'partially_refunded'].index(@hash.last[:state])>0)
  end
end
