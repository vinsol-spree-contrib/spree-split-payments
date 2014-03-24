Spree::PaymentMethod.class_eval do
  # [TODO] Lets not use lambda all the time. Use only when needed.
  scope :supporting_partial_payments, -> { where(for_partial: true) }
end
