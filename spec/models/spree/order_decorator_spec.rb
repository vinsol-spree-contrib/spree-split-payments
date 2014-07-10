require 'spec_helper'

class Spree::PaymentMethod::Partial < Spree::PaymentMethod
  def guest_checkout?
    false
  end
end

describe Spree::Order do
  let!(:user) { Spree::User.create! :email => 'test@example.com', :password => 'password' }
  let!(:order) { Spree::Order.create!(:email => 'test-account@myweb.com', :total => 500, :user_id => user.id) }
  let!(:partial_payment_method) { Spree::PaymentMethod::Partial.create! :for_partial => true, :name => 'partial_payment_method', :active => true, :display_on => "", :environment => 'test' }
  let!(:check) { Spree::PaymentMethod.create! :name => 'check', :active => true, :display_on => "", :environment => 'test' }
  let!(:credit_card) { Spree::PaymentMethod.create! :name => 'credit card', :active => true, :display_on => "", :environment => 'test' }

  before do
    @payment1 = Spree::Payment.create! :payment_method_id => partial_payment_method.id, :state => 'checkout', :order_id => order.id
    @payment2 = Spree::Payment.create! :payment_method_id => partial_payment_method.id, :state => 'completed', :order_id => order.id
    @payment3 = Spree::Payment.create! :payment_method_id => partial_payment_method.id, :state => "pending", :order_id => order.id
    @payment4 = Spree::Payment.create! :payment_method_id => partial_payment_method.id, :state => 'checkout', :order_id => order.id

    @payment_source = {credit_card.id => {:number => 'credit card number', :cvv => 'cvv'}}

    @updating_params = {:order => {:payments_attributes => { "0" => { :payment_method_id => credit_card.id }, '1' => { :payment_method_id => partial_payment_method.id, :amount => 100 }, '2' => { :payment_method_id => partial_payment_method.id, :amount => 200} } }, :payment_source => @payment_source }

    order.instance_variable_set(:@updating_params, @updating_params)
  end
  
  context 'when state is payment' do
    before do
      order.state = 'payment'
    end

    it "ensures only one non partial payment method is present" do
      order.should_receive(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
      order.save
    end

    it "invalidates old payments" do
      order.should_receive(:invalidate_old_payments)
      order.save
    end
  end

  context 'when state is not payment' do
    before do
      order.state = 'address'
    end

    it "does not run payments validation" do
      order.should_not_receive(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
      order.save
    end

    it "does not invalidate old payments" do
      order.should_not_receive(:invalidate_old_payments)
      order.save
    end
  end

  describe "#available_payment_methods" do
    context 'when guest checkout' do
      before do
        order.update_attribute(:user_id, nil)
      end

      it 'returns those available checkout payment methods for which guest_checkout is true' do
        order.available_payment_methods.map(&:name).should =~ [check, credit_card].map(&:name)
      end
    end

    context 'when user logged in' do
      it 'returns all available payment methods' do
        order.available_payment_methods.map(&:name).should =~ [check, credit_card, partial_payment_method].map(&:name)
      end
    end
  end

  describe "#available_partial_payments" do
    it { order.available_partial_payments.should =~ [partial_payment_method] }
  end

  describe "#checkout_payments" do
    it "return payments with state equal to checkout" do
      order.send(:checkout_payments).should =~ [@payment1, @payment4]
    end
  end

  describe "#invalidate_old_payments" do
    before do
      @payment5 = order.payments.create! :payment_method_id => partial_payment_method.id, :state => 'checkout', :order_id => order.id, :not_to_be_invalidated => true
      @payment6 = order.payments.create! :payment_method_id => partial_payment_method.id, :state => 'checkout', :order_id => order.id, :not_to_be_invalidated => true
    end
    
    it "marks payment1 as invalid" do
      order.send(:invalidate_old_payments)
      @payment1.reload
      @payment1.should be_invalid
    end

    it "marks payment4 as invalid" do
      order.send(:invalidate_old_payments)
      @payment4.reload
      @payment4.should be_invalid
    end

    it "does not change payment2 state" do
      order.send(:invalidate_old_payments)
      @payment2.reload
      @payment2.should be_completed
    end

    it "does not change payment3 state" do
      order.send(:invalidate_old_payments)
      @payment3.reload
      @payment3.should be_pending
    end

    it 'does not change payment5 state' do
      order.send(:invalidate_old_payments)
      @payment5.reload
      @payment5.should be_checkout
    end

    it 'does not change payment6 state' do
      order.send(:invalidate_old_payments)
      @payment6.reload
      @payment6.should be_checkout
    end
  end

  describe "#ensure_only_one_non_partial_payment_method_present_if_multiple_payments" do
    context 'when more than one non_partial_payment_method present' do
      before do
        order.payments.create! :payment_method_id => check.id, :state => 'checkout'
        order.payments.create! :payment_method_id => credit_card.id, :state => 'checkout'
      end

      it "sets errors" do
        order.send(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
        order.errors[:base].should eq(["Only one non partial payment method can be clubbed with partial payments."])
      end

      it "returns false" do
        order.send(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments).should be_false
      end
    end

    context 'when not more than one non_partial_payment_method present' do
      before do
        order.payments.create! :payment_method_id => check.id, :state => 'checkout'
      end

      it 'does not set errors' do
        order.send(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
        order.errors.should be_empty
      end
    end
  end

  describe "#update_params_payment_source" do
    def update_params_payment_source
      order.send(:update_params_payment_source)
    end

    context 'when state is payment' do
      before do
        order.update_attribute(:state, 'payment')
      end

      it 'inserts source params' do
        order.should_receive(:insert_source_params)
        update_params_payment_source
      end

      it 'sets remaining amount to non partial payment method' do
        update_params_payment_source
        @updating_params[:order][:payments_attributes]['0'][:amount].should eq(200)
      end
    end
  end

  describe "#insert_source_params" do
    def insert_source_params
      order.send(:insert_source_params)
    end

    it "inserst source attributes" do
      insert_source_params
      @updating_params[:order][:payments_attributes]['0'][:source_attributes].should eq(@payment_source[credit_card.id])
    end

    it "deletes payment source" do
      insert_source_params
      @updating_params[:payment_source].should eq(nil)
    end
  end

  describe "#order_total_after_partial_payments" do
    it "returns remaing amount after paying through partial payments" do
      order.send(:order_total_after_partial_payments).should eq(200)
    end
  end
end