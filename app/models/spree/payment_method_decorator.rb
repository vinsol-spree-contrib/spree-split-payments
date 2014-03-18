Spree::PaymentMethod.class_eval do
  scope :supporting_partial_payments, -> { where(for_partial: true) }
end