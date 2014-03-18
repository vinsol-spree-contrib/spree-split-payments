require 'spec_helper'

describe 'Spree::User' do
  let(:user) { Spree::User.new }
  let(:order) { Spree::Order.new}
  describe 'maximum_partial_payment_for_payment_method' do
    before do
      @test_payment_method = Spree::PaymentMethod.create!(:name => 'test_method', :type => "Spree::Gateway::Bogus")
      allow(user).to receive(:bogus_for_partial_payments).and_return(10)
    end

    it 'calls for method corresponding to payment method class name' do
      expect(user).to receive(:bogus_for_partial_payments).and_return(10)
      user.maximum_partial_payment_for_payment_method(@test_payment_method).should eq(10)
    end
  end
end