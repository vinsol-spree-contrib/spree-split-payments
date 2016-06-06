require 'spec_helper'

class Spree::PaymentMethod::Partial < Spree::PaymentMethod
  def guest_checkout?
    false
  end
end

describe Spree::Order do
  let!(:user) { Spree::User.create! email: 'test@example.com', password: 'password' }
  let!(:order) { Spree::Order.create!(email: 'test-account@myweb.com', total: 500, user_id: user.id) }
  let!(:partial_payment_method) { Spree::PaymentMethod::Partial.create! for_partial: true, name: 'partial_payment_method', active: true, display_on: "" }
  let!(:check) { Spree::PaymentMethod.create! name: 'check', active: true, display_on: "" }
  let!(:credit_card) { Spree::PaymentMethod.create! name: 'credit card', active: true, display_on: "" }

  before do
    @payment1 = Spree::Payment.create! payment_method_id: partial_payment_method.id, state: 'checkout', order_id: order.id
    @payment2 = Spree::Payment.create! payment_method_id: partial_payment_method.id, state: 'completed', order_id: order.id
    @payment3 = Spree::Payment.create! payment_method_id: partial_payment_method.id, state: "pending", order_id: order.id
    @payment4 = Spree::Payment.create! payment_method_id: partial_payment_method.id, state: 'checkout', order_id: order.id

    @payment_source = {credit_cardid: {number: 'credit card number', cvv: 'cvv'}}

    @updating_params = {order: {payments_attributes: { "0" => { payment_method_id: credit_card.id }, '1' => { payment_method_id: partial_payment_method.id, amount: 100 }, '2' => { payment_method_id: partial_payment_method.id, amount: 200} } }, payment_source: @payment_source }

    order.instance_variable_set(:@updating_params, @updating_params)
  end

  context 'when state is payment' do
    before do
      order.state = 'payment'
    end

    it "ensures only one non partial payment method is present" do
      expect(order).to receive(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
      order.save
    end

    it "invalidates old payments" do
      expect(order).to receive(:invalidate_old_payments)
      order.save
    end
  end

  context 'when state is not payment' do
    before do
      order.state = 'address'
    end

    it "does not run payments validation" do
      expect(order).not_to receive(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
      order.save
    end

    it "does not invalidate old payments" do
      expect(order).not_to receive(:invalidate_old_payments)
      order.save
    end
  end

  describe "#available_payment_methods" do
    context 'when guest checkout' do
      before do
        order.update_attribute(:user_id, nil)
      end

      it 'returns those available checkout payment methods for which guest_checkout is true' do
        expect(order.available_payment_methods.map(&:name)).to match_array([check, credit_card].map(&:name))
      end
    end

    context 'when user logged in' do
      it 'returns all available payment methods' do
        expect(order.available_payment_methods.map(&:name)).to match_array([check, credit_card, partial_payment_method].map(&:name))
      end
    end
  end

  describe "#available_partial_payments" do
    it { expect(order.available_partial_payments).to match_array([partial_payment_method]) }
  end

  describe "#checkout_payments" do
    it "return payments with state equal to checkout" do
      expect(order.send(:checkout_payments)).to match_array([@payment1, @payment4])
    end
  end

  describe "#invalidate_old_payments" do
    before do
      @payment5 = order.payments.create! payment_method_id: partial_payment_method.id, state: 'checkout', order_id: order.id, not_to_be_invalidated: true
      @payment6 = order.payments.create! payment_method_id: partial_payment_method.id, state: 'checkout', order_id: order.id, not_to_be_invalidated: true
    end

    it "marks payment1 as invalid" do
      order.send(:invalidate_old_payments)
      @payment1.reload
      expect(@payment1).to be_invalid
    end

    it "marks payment4 as invalid" do
      order.send(:invalidate_old_payments)
      @payment4.reload
      expect(@payment4).to be_invalid
    end

    it "does not change payment2 state" do
      order.send(:invalidate_old_payments)
      @payment2.reload
      expect(@payment2).to be_completed
    end

    it "does not change payment3 state" do
      order.send(:invalidate_old_payments)
      @payment3.reload
      expect(@payment3).to be_pending
    end

    it 'does not change payment5 state' do
      order.send(:invalidate_old_payments)
      @payment5.reload
      expect(@payment5).to be_checkout
    end

    it 'does not change payment6 state' do
      order.send(:invalidate_old_payments)
      @payment6.reload
      expect(@payment6).to be_checkout
    end
  end

  describe "#ensure_only_one_non_partial_payment_method_present_if_multiple_payments" do
    context 'when more than one non_partial_payment_method present' do
      before do
        order.payments.create! payment_method_id: check.id, state: 'checkout'
        order.payments.create! payment_method_id: credit_card.id, state: 'checkout'
      end

      it "sets errors" do
        order.send(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
        expect(order.errors[:base]).to eq(["Only one non partial payment method can be clubbed with partial payments."])
      end

      it "returns false" do
        expect(order.send(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)).to be_falsey
      end
    end

    context 'when not more than one non_partial_payment_method present' do
      before do
        order.payments.create! payment_method_id: check.id, state: 'checkout'
      end

      it 'does not set errors' do
        order.send(:ensure_only_one_non_partial_payment_method_present_if_multiple_payments)
        expect(order.errors).to be_empty
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
        expect(order).to receive(:insert_source_params)
        update_params_payment_source
      end

      it 'sets remaining amount to non partial payment method' do
        update_params_payment_source
        expect(@updating_params[:order][:payments_attributes]['0'][:amount]).to eq(200)
      end
    end
  end

  describe "#insert_source_params" do
    def insert_source_params
      order.send(:insert_source_params)
    end

    it "inserst source attributes" do
      insert_source_params
      expect(@updating_params[:order][:payments_attributes]['0'][:source_attributes]).to eq(@payment_source[credit_card.id])
    end

    it "deletes payment source" do
      insert_source_params
      expect(@updating_params[:payment_source]).to eq(nil)
    end
  end

  describe "#order_total_after_partial_payments" do
    it "returns remaing amount after paying through partial payments" do
      expect(order.send(:order_total_after_partial_payments)).to eq(200)
    end
  end
end
