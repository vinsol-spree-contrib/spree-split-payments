Spree::Order.class_eval do
  before_validation :invalidate_old_payments, if: :payment?
  validate :ensure_only_one_non_partial_payment_method_present_if_multiple_payments, if: :payment?

  def available_payment_methods
    @available_payment_methods ||= Spree::PaymentMethod.available_on_checkout(user ? false : true)
  end

  def update_from_params(params, permitted_params, request_env = {})
    success = false
    @updating_params = params
    run_callbacks :updating_from_params do
      # Set existing card after setting permitted parameters because
      # rails would slice parameters containg ruby objects, apparently
      existing_card_id = @updating_params[:order] ? @updating_params[:order].delete(:existing_card) : nil

      attributes = @updating_params[:order] ? @updating_params[:order].permit(permitted_params).delete_if { |_k, v| v.nil? } : {}

      if existing_card_id.present?
        credit_card = Spree::CreditCard.find existing_card_id
        if credit_card.user_id != user_id || credit_card.user_id.blank?
          raise Core::GatewayError.new Spree.t(:invalid_credit_card)
        end

        credit_card.verification_value = params[:cvc_confirm] if params[:cvc_confirm].present?

        #Now we have multiple multiple payment methods, so we have to insert payment attributes for all of them
        #this why we have generate a key(payment_method_id) for each payment's attributes

        attributes[:payments_attributes][credit_card.payment_method_id] = {}
        attributes[:payments_attributes][credit_card.payment_method_id][:source] = credit_card
        attributes[:payments_attributes][credit_card.payment_method_id][:amount] = total
        attributes[:payments_attributes][credit_card.payment_method_id][:not_to_be_invalidated] = true
        attributes[:payments_attributes][credit_card.payment_method_id][:payment_method_id] = credit_card.payment_method_id
      end

      if attributes[:payments_attributes]
        # Since now we will have multiple payment attributes,
        # we need loop and set request_env for every attributes.
        attributes[:payments_attributes].each do |index, _attrs|
          _attrs[:request_env] = request_env
        end
      end
      success = update_attributes(attributes.permit!)
      set_shipments_cost if shipments.any?
    end

    @updating_params = nil
    success
  end

  def available_partial_payments
    @available_partial_payments ||= available_payment_methods.select(&:for_partial?)
  end

  private

  def checkout_payments
    payments.select { |payment| payment.checkout? }
  end

  def invalidate_old_payments
    checkout_payments.each do |payment|
      if !payment.not_to_be_invalidated
        payment.invalidate!
      end
    end
  end

  def ensure_only_one_non_partial_payment_method_present_if_multiple_payments
    if checkout_payments.many?
      payment_method_ids = checkout_payments.map(&:payment_method_id)
      non_partial_payment_method_ids =  payment_method_ids - available_partial_payments.map(&:id)
      if non_partial_payment_method_ids.size > 1
        errors[:base] << "Only one non partial payment method can be clubbed with partial payments."
        return false
      end
    end
  end

  def update_params_payment_source
    if has_checkout_step?("payment") && self.payment?
      @updating_params[:order][:payments_attributes] ||= {}
      insert_source_params
      if @updating_params[:order][:payments_attributes]['0']
        @updating_params[:order][:payments_attributes]['0'][:amount] = order_total_after_partial_payments
      end
    end
  end


  def insert_source_params
    if @updating_params[:payment_source].present?
      @updating_params[:order][:payments_attributes].values.each do |payment_attrs|
        source_params = @updating_params[:payment_source][payment_attrs[:payment_method_id]]
        payment_attrs[:not_to_be_invalidated] = true
        payment_attrs[:source_attributes] = source_params if source_params
      end
      @updating_params.delete(:payment_source)
    end
  end

  def order_total_after_partial_payments
    amount = 0
    @updating_params[:order][:payments_attributes].values.each do |payment_attrs|
      amount += payment_attrs[:amount].to_f
    end
    outstanding_balance - amount
  end

end
