require 'spec_helper'

describe 'Spree::Payment' do
  let!(:order) { Spree::Order.create! :email => 'test@example.com' }
  let!(:partial_payment_method) { Spree::PaymentMethod.create! :name => 'partial payment method', :for_partial => true }
  let!(:non_partial_payment_method) { Spree::PaymentMethod.create! :name => 'non_partial payment method'}
  let!(:partial_payment1) { Spree::Payment.create! :payment_method_id => partial_payment_method.id, :order_id => order.id }
  let!(:partial_payment2) { Spree::Payment.create! :payment_method_id => partial_payment_method.id, :order_id => order.id }
  let!(:non_partial_payment1) { Spree::Payment.create! :payment_method_id => non_partial_payment_method.id, :order_id => order.id }
  let!(:non_partial_payment2) { Spree::Payment.create! :payment_method_id => non_partial_payment_method.id, :order_id => order.id }

  describe "self.partial" do
    it { Spree::Payment.partial.should =~ [partial_payment1, partial_payment2] }
  end

  context 'before_create' do
    before do
      @payment = Spree::Payment.new :payment_method_id => partial_payment_method.id, :order_id => order.id
    end

    it "marks payment as partial" do
      @payment.should_receive(:mark_partial_if_payment_method_is_partial)
      @payment.save!
    end
  end


  describe "#mark_partial_if_payment_method_is_partial" do
    before do
      @payment = Spree::Payment.new
    end

    context 'when payment_method is partial' do
      before do
        @payment.payment_method = partial_payment_method
      end

      it "sets is_partial to true" do
        @payment.send(:mark_partial_if_payment_method_is_partial)
        @payment.is_partial?.should be_true
      end
    end

    context 'when payment_method is not partial' do
      before do
        @payment.payment_method = non_partial_payment_method
      end

      it "does not set is_partial to true" do
        @payment.send(:mark_partial_if_payment_method_is_partial)
        @payment.is_partial?.should be_false
      end
    end
  end
end
