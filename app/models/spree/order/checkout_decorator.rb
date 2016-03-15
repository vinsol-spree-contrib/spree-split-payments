module SpreeSplitPayments::OrderCheckoutDecorator
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
end

Spree::Order.send(:prepend, SpreeSplitPayments::OrderCheckoutDecorator)
