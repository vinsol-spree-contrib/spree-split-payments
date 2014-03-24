Spree::PaymentMethod.class_eval do
  # [TODO] Lets not use lambda all the time. Use only when needed.
  scope :supporting_partial_payments, -> { active.where(for_partial: true).order('partial_priority desc') }

  def self.active
    where(active: true)
  end
end
