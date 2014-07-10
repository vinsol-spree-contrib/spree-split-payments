class Spree::PaymentMethod::Wallet < Spree::PaymentMethod
  def guest_checkout?
    false
  end
end

class Spree::PaymentMethod::LoyaltyPoints < Spree::PaymentMethod
  def guest_checkout?
    false
  end
end