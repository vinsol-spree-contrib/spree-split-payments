Spree::PaymentMethod.class_eval do
  scope :supporting_partial_payments, -> { active.where(for_partial: true).order('partial_priority desc') }

  def self.active
    where(active: true)
  end
end
