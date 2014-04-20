##########################
### Delete Credit Card ###
##########################

class Paypkg
  # Delete a card from the vault. If Paypal already removed the card
  # because it expired, just ignore the error. NO JSON STRING is
  # returned with this call.
  def delete_credit_card(vault_id)
    call_paypal("/v1/vault/credit-card/#{vault_id}", nil, :method => :delete)
    return (@status.last=='204') && (@hash.last==nil)
  end
end
