require 'spec_helper'

describe 'Spree::PaymentMethod' do
  context 'scope' do
    before do
      @first_partial_method = Spree::PaymentMethod.create!(
                                        name: 'test_method',
                                        for_partial: true)
      @second_partial_method = Spree::PaymentMethod.create!(
                                        name: 'test_method_1',
                                        for_partial: true)
      @test_payment_method = Spree::PaymentMethod.create!(
                                        name: 'test_method_2')
      @partial_payment_methods = Spree::PaymentMethod
                                 .supporting_partial_payments
    end

    it { @partial_payment_methods.should include(@first_partial_method) }
    it { @partial_payment_methods.should include(@second_partial_method) }
    it { @partial_payment_methods.should_not include(@test_payment_method) }
  end
end
