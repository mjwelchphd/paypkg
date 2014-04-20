######################################
### Retrieve a card from the vault ###
######################################

class Paypkg
  # Retrieve a card from the vault.
  # @param vault_id [String] The vault_id PayPal assigned when
  #   you stored this card.
  # @return [Hash] The card data, less the card number: only the
  #   last 4 digits of the card number are returned. You can get
  #   an error from this call if the card expired and PayPal
  #   automatically removed it from the vault. If that happens,
  #   you should delete it from your database.
  def retrieve_credit_card(vault_id)
    call_paypal("/v1/vault/credit-card/#{vault_id}")
    return (@status.last=='200') && (@hash.last[:state]=='ok')
  end
end
