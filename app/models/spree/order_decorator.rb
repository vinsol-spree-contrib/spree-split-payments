Spree::Order.class_eval do
  before_validation :invalidate_old_payments, :if => :payment?
  validate :ensure_only_one_non_partial_payment_method_present_if_multiple_payments, :if => :payment?

  def available_payment_methods
    @available_payment_methods ||= Spree::PaymentMethod.available_on_checkout(user ? false : true)
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
