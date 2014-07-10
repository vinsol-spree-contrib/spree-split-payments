Spree::Payment.class_eval do
  attr_accessor :not_to_be_invalidated
  before_create :mark_partial_if_payment_method_is_partial

  def self.partial
    where(is_partial: true)
  end

  private
    def invalidate_old_payments
    end

    def mark_partial_if_payment_method_is_partial
      self.is_partial = true if payment_method.for_partial?
    end
end