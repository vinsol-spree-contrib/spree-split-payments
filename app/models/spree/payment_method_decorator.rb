Spree::PaymentMethod.class_eval do
  # scope :supporting_partial_payments, -> { active.where(for_partial: true).order('partial_priority desc') }

  def self.active
    where(active: true)
  end

  def self.available_on_checkout(guest_checkout=false)
    all.select do |p|
      p.active && 
      (p.display_on.blank? || p.display_on == "frontend" || p.display_on == "both") && 
      (!guest_checkout || p.guest_checkout?) && 
      (p.environment == Rails.env || p.environment.blank?)
    end
  end
end
