class PaypkgTestController < ApplicationController

  def test1
    @notes = []

    card_id = nil
    begin
      pp = Paypkg.new(session)

      @ok = pp.validate_credit_card('visa', '4417119669820331', '11', '2018', '999', \
        'Betsy', 'Buyer', '111 First Street', 'Saratoga', 'CA', '95070', 'US')
      if @ok then
        @notes << "validate_credit_card OK"
        authorization_data = pp.hash.first
        void_data = pp.hash.last
        auth_payment_id = authorization_data[:id]
        auth_id = authorization_data[:transactions][0][:related_resources][0][:authorization][:id]
        void_payment_id = void_data[:parent_payment]
        void_id = void_data[:id]
        if (auth_payment_id==void_payment_id) && (auth_id==void_id)
          @notes << "validate_credit_card Passed"
        else
          @notes << "validate_credit_card Failed"
        end
      else
        @notes << "validate_credit_card NOT OK"
      end


      @ok = pp.store_credit_card('visa', '4417119669820331', '11', '2018', '999', \
        'Betsy', 'Buyer', '111 First Street', nil, 'Saratoga', 'CA', '95070', 'US', 'betsy')
      if @ok then
        @notes << "store_credit_card OK"
        card_data = pp.hash.last
        card_id = card_data[:id]
      else
        @notes << "store_credit_card NOT OK"
        card_id = nil
      end


      if card_id
        @ok = pp.retrieve_credit_card(card_id)
        if @ok then
          @notes << "retrieve_credit_card OK"
          if (card_data==pp.hash.last)
            @notes << "retrieve_credit_card Passed"
          else
            @notes << "retrieve_credit_card Failed"
          end
        else
          @notes << "retrieve_credit_card NOT OK"
        end
      else
        @notes << "retrieve_credit_card NOT TESTED"
      end


      @ok = pp.accept_tendered_cc_payment('visa', '4417119669820331', '11', '2018', '999', 'Betsy', 'Buyer', 3.0, "Tendered Payment")
      if @ok then
        @notes << "accept_tendered_cc_payment OK"
        tendered_data = pp.hash.last
        payment_id = tendered_data[:id]
        sale_id = tendered_data[:transactions][0][:related_resources][0][:sale][:id]
      else
        @notes << "accept_tendered_cc_payment NOT OK"
        payment_id = nil
        sale_id = nil
      end

      if sale_id
        @ok = pp.retrieve_sale_transaction(sale_id)
        if @ok then
          @notes << "retrieve_sale_transaction OK"
          if (sale_id==pp.hash.last[:id]) && (payment_id==pp.hash.last[:parent_payment])
            @notes << "retrieve_sale_transaction Passed"
          else
            @notes << "retrieve_sale_transaction Failed"
          end
        else
          @notes << "retrieve_sale_transaction NOT OK"
        end
      else
        @notes << "retrieve_sale_transaction NOT TESTED"
      end

      if sale_id
        @ok = pp.refund_sale(sale_id,2.0)
        if @ok then
          @notes << "refund_sale OK"
          refund_data = pp.hash.last
          refund_id = refund_data[:id]
          if (refund_data[:sale_id]==sale_id) && (refund_data[:amount][:total]=="2.00")
            @notes << "refund_sale Passed"
          else
            @notes << "refund_sale Failed"
          end
        else
          @notes << "refund_sale NOT OK"
          refund_id = nil
        end
      else
        @notes << "refund_sale NOT TESTED"
        refund_id = nil
      end

      if card_id
        @ok = pp.accept_stored_cc_payment(card_id, 3.0, 'Test Charge', 'test@example.com', 'betsy')
        if @ok then
          @notes << "accept_stored_cc_payment OK"
          stored_data = pp.hash.last
          payment_id = stored_data[:id]
          sale_id = stored_data[:transactions][0][:related_resources][0][:sale][:id]
        else
          @notes << "accept_stored_cc_payment NOT OK"
          payment_id = nil
          sale_id = nil
        end
      else
        @notes << "accept_stored_cc_payment NOT TESTED"
        payment_id = nil
        sale_id = nil
      end

      if sale_id
        @ok = pp.retrieve_sale_transaction(sale_id)
        if @ok then
          @notes << "retrieve_sale_transaction OK"
          if (sale_id==pp.hash.last[:id]) && (payment_id==pp.hash.last[:parent_payment])
            @notes << "retrieve_sale_transaction Passed"
          else
            @notes << "retrieve_sale_transaction Failed"
          end
        else
          @notes << "retrieve_sale_transaction NOT OK"
        end
      else
        @notes << "retrieve_sale_transaction NOT OK"
      end

      if sale_id
        @ok = pp.refund_sale(sale_id,3.0)
        if @ok then
          @notes << "refund_sale OK"
          refund_data = pp.hash.last
          refund_id = refund_data[:id]
          if (refund_data[:sale_id]==sale_id) && (refund_data[:amount][:total]=="3.00")
            @notes << "refund_sale Passed"
          else
            @notes << "refund_sale Failed"
          end
        else
          @notes << "refund_sale NOT OK"
          refund_id = nil
        end
      else
        @notes << "refund_sale NOT TESTED"
        refund_id = nil
      end

      if refund_id
        @ok = pp.retrieve_refund_transaction(refund_id)
        if @ok then
          @notes << "retrieve_refund_transaction OK"
          if (sale_id==pp.hash.last[:sale_id]) && (payment_id==pp.hash.last[:parent_payment])
            @notes << "retrieve_refund_transaction Passed"
          else
            @notes << "retrieve_refund_transaction Failed"
          end
        else
          @notes << "retrieve_refund_transaction NOT OK"
        end
      else
        @notes << "retrieve_refund_transaction NOT TESTED"
      end

      if card_id
        @ok = pp.delete_credit_card(card_id)
        if @ok then
          @notes << "delete_credit_card OK"
        else
          @notes << "delete_credit_card NOT OK"
        end
      else
        @notes << "delete_credit_card NOT OK"
      end

    rescue => e
      @notes << "Processing NOT passed because %s"%e.to_s

    ensure
      if card_id
        pp.delete_credit_card(card_id)
      end
    end

  end


  def test2
    pp = Paypkg.new(session)
    @ok = pp.accept_pp_payment(3.0, 'Test Charge', 'paypkg_test/approved', 'paypkg_test/cancelled', 'betsy')
    redirect_to pp.link if @ok
  end


########################
### CALLBACK ACTIONS ###
########################

  def approved
    pp = Paypkg.new(session)
    @ok = pp.execute_payment(params[:PayerID],session[:payment_id])
    if @ok
      payment_data = pp.hash.last
      @payment_id = payment_data[:id]
      @sale_id = payment_data[:transactions][0][:related_resources][0][:sale][:id]
      @amount = payment_data[:transactions][0][:related_resources][0][:sale][:amount][:total]
      session.delete(:payment_id)
      @note = nil
    else
      @note = pp.hash.last.pretty_inspect
    end
  end

  def cancelled
  end

end
