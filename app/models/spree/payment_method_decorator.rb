Spree::PaymentMethod.class_eval do

  def self.available_on_checkout(guest_checkout=false)
    all.select do |payment_method|
      payment_method.active &&
      (payment_method.display_on.blank? || payment_method.display_on == "frontend" || payment_method.display_on == "both") &&
      (!guest_checkout || payment_method.guest_checkout?)
    end
  end

  def guest_checkout?
    true
  end
end
