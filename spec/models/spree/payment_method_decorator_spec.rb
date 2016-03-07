require 'spec_helper'

describe "Spree::PaymentMethod" do
  let!(:wallet) { Spree::PaymentMethod::Wallet.create! :for_partial => true, :name => 'wallet', :active => true, :display_on => "" }
  let!(:check) { Spree::PaymentMethod.create! :name => 'check', :active => true, :display_on => "" }
  let!(:credit_card) { Spree::PaymentMethod.create! :name => 'credit card', :active => true, :display_on => "" }
  let!(:loyalty_points) { Spree::PaymentMethod::LoyaltyPoints.create! :for_partial => true, :name => 'loyalty points', :active => true, :display_on => '' }
  let!(:inactive_payment_method) { Spree::PaymentMethod.create! :active => false, :name => 'inactive' }


  describe "self.available_on_checkout" do
    it { Spree::PaymentMethod.available_on_checkout(true).should =~ [check, credit_card] }
    it { Spree::PaymentMethod.available_on_checkout(false).should =~ [check, credit_card, wallet, loyalty_points] }
  end

  describe "#guest_checkout?" do
    it { Spree::PaymentMethod.new.guest_checkout?.should be_true }
  end
end
