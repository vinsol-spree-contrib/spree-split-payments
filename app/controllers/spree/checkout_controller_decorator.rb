Spree::CheckoutController.class_eval do
  before_action :insert_payments_using_split_payments,
                only: :update, if: -> { process_split_payments? }

  private
    #[TODO] create_split_payments name seems more appropriate. What you say?
    # This should be private method
    def insert_payments_using_split_payments
      @order_balance_after_split_payment = @order.outstanding_balance

      params['order']['split_payments'].each do |split_payment|
        payment_method = Spree::PaymentMethod.supporting_partial_payments.where(id: split_payment['payment_method_id']).first
        if payment_method
          payment_amount = find_amount_for_partial_payment_for(payment_method);
          insert_split_payment_for(split_payment['payment_method_id'], payment_amount) unless payment_amount.zero?
        end
      end
      params['order'].delete('split_payments')
    end

    def insert_split_payment_for(payment_method_id, amount)
      params[:order][:payments_attributes].insert(0, 
        { payment_method_id: payment_method_id,
          is_partial: true,
          amount: amount
        }
      )
      @order_balance_after_split_payment -= amount
    end

    def find_amount_for_partial_payment_for(payment_method)
      payment_amount = spree_current_user.maximum_partial_payment_for_payment_method(payment_method)
      @order_balance_after_split_payment < payment_amount ? @order_balance_after_split_payment : payment_amount    
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
          params[:order][:payments_attributes].last[:amount] = @order_balance_after_split_payment || @order.outstanding_balance
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
end
