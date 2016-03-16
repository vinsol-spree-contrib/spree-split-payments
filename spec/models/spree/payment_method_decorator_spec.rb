require 'spec_helper'

describe "Spree::PaymentMethod" do
  let!(:wallet) { Spree::PaymentMethod::Wallet.create! :for_partial => true, :name => 'wallet', :active => true, :display_on => "" }
  let!(:check) { Spree::PaymentMethod.create! :name => 'check', :active => true, :display_on => "" }
  let!(:credit_card) { Spree::PaymentMethod.create! :name => 'credit card', :active => true, :display_on => "" }
  let!(:loyalty_points) { Spree::PaymentMethod::LoyaltyPoints.create! :for_partial => true, :name => 'loyalty points', :active => true, :display_on => '' }
  let!(:inactive_payment_method) { Spree::PaymentMethod.create! :active => false, :name => 'inactive' }
  let!(:production_payment_method) { Spree::PaymentMethod.create! :active => true, :name => 'production payment method' }


  describe "self.available_on_checkout" do
    it { expect(Spree::PaymentMethod.available_on_checkout(true)).to match_array([check, credit_card, production_payment_method]) }
    it { expect(Spree::PaymentMethod.available_on_checkout(false)).to match_array([check, credit_card, wallet, loyalty_points, production_payment_method]) }
  end

  describe "#guest_checkout?" do
    it { expect(Spree::PaymentMethod.new.guest_checkout?).to be_truthy }
  end
end
