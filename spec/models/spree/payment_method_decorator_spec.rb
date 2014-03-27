require 'spec_helper'

describe 'Spree::PaymentMethod' do
  context 'scope' do
    before :all do
      @first_partial_method = Spree::PaymentMethod.create!(
                                        name: 'test_method',
                                        for_partial: true,
                                        partial_priority: 1)
      @second_partial_method = Spree::PaymentMethod.create!(
                                        name: 'test_method_1',
                                        for_partial: true,
                                        partial_priority: 2)
      @test_method = Spree::PaymentMethod.create!(
                                        name: 'test_method_2')
      @inactive_partial_method = Spree::PaymentMethod.create!(
                                        name: 'test_method_1',
                                        for_partial: true,
                                        active: false)
      @inactive_method = Spree::PaymentMethod.create!(
                                        name: 'test_method_1',
                                        active: false)
      @partial_methods = Spree::PaymentMethod
                                 .supporting_partial_payments
      @active_methods = Spree::PaymentMethod.active
    end

    it 'supporting_partial_payments:is_partial? and active?' do
      @partial_methods.to_a.should eq([@second_partial_method,
                                       @first_partial_method])

      @partial_methods.should_not include(@test_method,
                                          @inactive_method,
                                          @inactive_partial_method)
    end

    it 'active:active?' do
      @active_methods.should include(@first_partial_method,
                                     @second_partial_method,
                                     @test_method)
      @active_methods.should_not include(@inactive_method,
                                         @inactive_partial_method)
    end
  end
end
