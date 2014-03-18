require 'spec_helper'

describe 'Spree::PaymentMethod' do
  context 'scope' do
    before do
      @first_partial_payment_method = Spree::PaymentMethod.create!(:name => 'test_method', :for_partial => true)
      @second_partial_payment_method = Spree::PaymentMethod.create!(:name => 'test_method_1', :for_partial => true)
      @test_payment_method = Spree::PaymentMethod.create!(:name => 'test_method_2')
    end

    it { Spree::PaymentMethod.supporting_partial_payments.should include(@first_partial_payment_method, @second_partial_payment_method) }
    it { Spree::PaymentMethod.supporting_partial_payments.should_not include(@test_payment_method) }
  end
end