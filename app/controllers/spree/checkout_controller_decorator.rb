Spree::CheckoutController.class_eval do
  # before_action :insert_payments_using_split_payments,
  #               only: :update, if: -> { process_split_payments? }

  private
    # def insert_payments_using_split_payments
    #   @order_balance_after_split_payment = @order.outstanding_balance

    #   params['order']['split_payments'].each do |split_payment|
    #     payment_method = Spree::PaymentMethod.supporting_partial_payments.where(id: split_payment['payment_method_id']).first
    #     if payment_method
    #       payment_amount = find_amount_for_partial_payment_for(payment_method);
    #       insert_split_payment_for(split_payment['payment_method_id'], payment_amount) unless payment_amount.zero?
    #     end
    #   end
    #   params['order'].delete('split_payments')
    # end

    # def insert_split_payment_for(payment_method_id, amount)
    #   params[:order][:payments_attributes].insert(0, 
    #     { payment_method_id: payment_method_id,
    #       is_partial: true,
    #       amount: amount
    #     }
    #   )
    #   @order_balance_after_split_payment -= amount
    # end

    # def find_amount_for_partial_payment_for(payment_method)
    #   spree_current_user.maximum_partial_payment_for_payment_method(payment_method)
    # end

    # over write this to use outstanding_amount instead of total amount
    # for payment_attributes amount assignment
    def object_params
      # has_checkout_step? check is necessary due to issue described in #2910
      if @order.has_checkout_step?('payment') && @order.payment?
        if params[:order][:payments_attributes]
          insert_source_params
          if params[:order][:payments_attributes][0]
            params[:order][:payments_attributes][0][:amount] = non_partial_payment_method_amount
          end
        end
      end

      if params[:order]
        params[:order].permit(permitted_checkout_attributes)
      else
        {}
      end
    end

    def insert_source_params
      if params[:payment_source].present?
        params[:order][:payments_attributes].values.each do |payment_attrs|
          source_params = params[:payment_source][payment_attrs[:payment_method_id]]
          payment_attrs[:not_to_be_invalidated] = true
          payment_attrs[:source_attributes] = source_params if source_params
        end
        params.delete(:payment_source)
      end
    end

    def non_partial_payment_method_amount
      amount = 0
      params[:order][:payments_attributes].values.each do |payment_attrs|
        amount += payment_attrs[:amount].to_f
      end
      @order.outstanding_balance - amount
    end

    # def payment_step?
    #   params[:state] == 'payment'
    # end

    # def process_split_payments?
    #   payment_step? && params['order']['split_payments']
    # end
end
