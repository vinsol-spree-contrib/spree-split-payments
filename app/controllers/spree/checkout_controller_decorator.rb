Spree::CheckoutController.class_eval do
  before_action :extract_partial_payments, :only => :update, if: -> { params[:state] == 'payment' && params['order']['split_payments'] }

  def extract_partial_payments
    payment_method_ids = params['order']['split_payments'].collect{ |attribute| attribute["payment_method_id"] }
    
    payment_method_ids.each do |payment_method_id| 
      payment_method = Spree::PaymentMethod.where(:id => payment_method_id).first
      if payment_method
        payment_amount = spree_current_user.maximum_partial_payment_for_payment_method(payment_method)
        outstanding_balance = @order.outstanding_balance
        payment_amount = outstanding_balance if outstanding_balance < payment_amount
        payment = @order.payments.create(:payment_method_id => payment_method_id, :state => 'pending', amount: payment_amount, :is_partial => true) unless payment_amount.zero?
      end
    end
  end

  #over write this to use outstanding_amount instead of total amount for payment_attributes amount assignment
  def object_params
    # has_checkout_step? check is necessary due to issue described in #2910
    if @order.has_checkout_step?("payment") && @order.payment?
      if params[:payment_source].present?
        source_params = params.delete(:payment_source)[params[:order][:payments_attributes].first[:payment_method_id].underscore]

        if source_params
          params[:order][:payments_attributes].first[:source_attributes] = source_params
        end
      end

      if (params[:order][:payments_attributes])
        params[:order][:payments_attributes].first[:amount] = @order.outstanding_balance
      end
    end

    if params[:order]
      params[:order].permit(permitted_checkout_attributes)
    else
      {}
    end
  end
end