#################################
### Retrieve Sale Transaction ###
#################################

class Paypkg
  # Use the sale_id to look up the sale.
  # @param sale_id [String] Required.
  # @return [json String] The same json string retured when
  #   the sale was orginally completed.
  def retrieve_sale_transaction(sale_id)
    call_paypal("/v1/payments/sale/#{sale_id}")
    return (@status.last=='200') && (['pending', 'completed', 'refunded', 'partially_refunded'].index(@hash.last[:state])>0)
  end
end
