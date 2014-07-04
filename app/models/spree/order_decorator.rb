Spree::Order.class_eval do
  # Spree::Order.state_machine.before_transition :to => :complete, :do => [:invalidate_old_payments]
  before_validation :invalidate_old_payments, :if => :payment?
  validate :ensure_only_one_non_partial_payment_method_present_if_multiple_payments, :if => :payment?

  private
  # def process_partial_payments
  #   self.payments.pending.partial.each { |payment| payment.complete }
  # end
  def checkout_payments
    payments.select { |payment| payment.checkout? }
  end

  def invalidate_old_payments
    checkout_payments.each do |payment|
      if payment.checkout? && !payment.not_to_be_invalidated
        payment.invalidate!
      end
    end
  end

  def ensure_only_one_non_partial_payment_method_present_if_multiple_payments
    if checkout_payments.many?
      payment_method_ids = checkout_payments.map(&:payment_method_id)
      non_partial_payment_method_ids =  payment_method_ids - Spree::PaymentMethod.supporting_partial_payments.map(&:id)
      if non_partial_payment_method_ids.size > 1
        errors[:base] << "Only one non partial payment method can be clubbed with partial payments."
        return false
      end
    end
  end
end
