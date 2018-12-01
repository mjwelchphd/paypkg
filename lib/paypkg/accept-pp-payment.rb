##############################
### Payment Through PayPal ###
##############################

class Paypkg
  # This method is intended for use when you want to charge
  # a user's PayPay account. The user will be required to give
  # an on-line approval.
  #
  # The two urls shown here must be in your controller, and
  # in your config/routes.rb file. See the execute_payment
  # method below. You should store the payment_id you get
  # back from this call (in session[:payment_id] here).
  #
  # @param amount
  # @param desc
  # @param approved_url
  # @param cancelled_url
  def accept_pp_payment(amount, desc, approved_url, cancelled_url)
    set_access_token # we need this here to set the @website
    formatted_amount = "%0.2f"%amount
    json, status = call_paypal("/v1/payments/payment", "{
      'intent':'sale',
      'redirect_urls':{
        'return_url':'#{@website}/#{approved_url}/',
        'cancel_url':'#{@website}/#{cancelled_url}/'
      },
      'payer':{
        'payment_method':'paypal'
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
    if (@status.last=='201') && (@hash.last[:state]=='created')
      @session[:payment_id] = @hash.last[:id]
      @link = @hash.last[:links].select{|link| link[:rel]=='approval_url'}[0][:href]
      return true
    else
      return false
    end
  end

  # This is executed by the code at the 'accepted' url.
  #
  # Your controller must provide two url's that look like
  # the code below, and are in your config/routes.rb
  #
  #   def approved
  #     pp = Paypkg.new(session)
  #     @ok = pp.execute_payment(params[:PayerID],session[:payment_id])
  #     ... more logic ...
  #   end
  # 
  #   def cancelled
  #     ... handle the user cancelling out ...
  #   end
  #
  # You should save the sale_id returned from this call in your
  # database.
  #
  # @param payer_id
  # @param payment_id
  def execute_payment(payer_id, payment_id)
    call_paypal("/v1/payments/payment/#{payment_id}/execute/", "{
      'payer_id' : '#{payer_id}'
    }")
    return (@status.last=='200') && (@hash.last[:state]=='approved')
  end
end
