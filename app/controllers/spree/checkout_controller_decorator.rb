Spree::CheckoutController.class_eval do
  before_action :create_split_payments,
                only: :update, if: -> { process_split_payments? }

  private
    #[TODO] create_split_payments name seems more appropriate. What you say?
    # This should be private method
    def create_split_payments
      payment_method_ids = extract_partial_payment_method_ids

      #[TODO] Shouldn't we get only active payment methods here. Also, can we find all payment methods at once here and use them.
      Spree::PaymentMethod.supporting_partial_payments.where(id: payment_method_ids).each do |payment_method|
        create_split_payment_for(payment_method)
      end
    end

    def extract_partial_payment_method_ids
      params['order']['split_payments']
      .map { |attribute| attribute['payment_method_id'] }
    end

    #[TODO] We should break this into smaller methods with appropriate names. Please discuss this with me.
    # over write this to use outstanding_amount instead of total amount
    # for payment_attributes amount assignment
    def object_params
      # has_checkout_step? check is necessary due to issue described in #2910
      if @order.has_checkout_step?('payment') && @order.payment?
        if params[:payment_source].present?
          source_params = params.delete(:payment_source)[params[:order][:payments_attributes].first[:payment_method_id].underscore]

          if source_params
            params[:order][:payments_attributes].first[:source_attributes] = source_params
          end
        end

        if params[:order][:payments_attributes]
          params[:order][:payments_attributes].first[:amount] = @order.outstanding_balance
        end
      end

      if params[:order]
        params[:order].permit(permitted_checkout_attributes)
      else
        {}
      end
    end

    def payment_step?
      params[:state] == 'payment'
    end

    def process_split_payments?
      #[TODO] We should extract first condition into a method. Say payment_state? OR is_payment_state? OR anything you thing suites best
      payment_step? && params['order']['split_payments']
    end
    
    #[TODO] This should  be a part of model and should be in a transition. If at any point somthing went wrong everything should rollback
    def create_split_payment_for(payment_method)
      payment_amount = spree_current_user.maximum_partial_payment_for_payment_method(payment_method)
      balance = @order.outstanding_balance
      payment_amount = balance if balance < payment_amount
      @order.payments.create(
        payment_method_id: payment_method.id,
        state: 'pending',
        amount: payment_amount,
        is_partial: true) unless payment_amount.zero?
    end
end
