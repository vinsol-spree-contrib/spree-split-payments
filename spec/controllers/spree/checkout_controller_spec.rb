require 'spec_helper'

describe Spree::CheckoutController do
  let(:user) { mock_model(Spree.user_class) }
  let(:order) { Spree::Order.new }
  let(:payment_method_partial_payment) { 10 }

  before(:each) do
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(order).to receive(:checkout_allowed?).and_return(true)
    allow(controller).to receive(:load_order_with_lock).and_return(true)
    user.stub(:last_incomplete_spree_order).and_return(order)
    allow(controller).to receive(:ensure_order_not_completed).and_return(true)
    allow(controller).to receive(:ensure_valid_state).and_return(true)
    controller.instance_variable_set(:@order, order)
    @payment_method = mock_model(Spree::PaymentMethod,
                                 type: 'Spree::PaymentMethod::Check')
    allow(Spree::PaymentMethod).to receive(:supporting_partial_payments).and_return(Spree::PaymentMethod)
    # allow(Spree::PaymentMethod).to receive(:where).with({:deleted_at=>nil}).and_return(Spree::PaymentMethod)
    allow(Spree::Payment.any_instance).to receive(:mark_pending_if_partial).and_return(true)
    allow(order).to receive(:update_attributes).and_return(false)
    allow(order).to receive(:outstanding_balance).and_return(100)
  end

  describe '#insert_payments_using_split_payments' do
    def send_request(params = {})
      put :update, params.merge!(use_route: 'spree')
    end

    context 'when state is not payment' do
      it { controller.should_not_receive(:insert_payments_using_split_payments) }
      after do
        send_request(
          order: {
            payments_attributes: [{ payment_method_id: '1' }] },
          state: 'delivery')
      end
    end

    context 'when state is payment but without any split payment' do
      it { controller.should_not_receive(:insert_payments_using_split_payments) }
      after do
        send_request(
          order: {
            payments_attributes: [{ payment_method_id: '1' }] },
          state: 'payment')
      end
    end

    context 'when state is payment and split payment attributes present' do
      context 'payment method not found' do
        it { expect(Spree::PaymentMethod).to receive(:supporting_partial_payments).and_return(Spree::PaymentMethod) } 
        it { Spree::PaymentMethod.should_receive(:where).with(id: '1').and_return([]) }
        it { expect(controller).to_not receive(:find_amount_for_partial_payment_for) }
      end

      context 'payment method is found' do
        before do
          allow(Spree::PaymentMethod).to receive(:where).with(id: '1').and_return([@payment_method])
          allow(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(payment_method_partial_payment)
          # allow(controller).to receive(:insert_split_payment_for).with('1', payment_method_partial_payment).and_return(true)
        end
        
        it { expect(Spree::PaymentMethod).to receive(:where).with(id: '1').and_return([@payment_method]) }  
        it { expect(order).to receive(:outstanding_balance).and_return(order.total) }

        context 'when payment amount is not zero' do
          it { expect(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(payment_method_partial_payment) }
          it { expect(controller).to receive(:insert_split_payment_for).with('1', payment_method_partial_payment).and_return(true) }
        end

        context 'when payment amount is zero' do
          before { allow(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(0) }
          
          it { expect(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(0) }
          it { expect(controller).to_not receive(:insert_split_payment_for) }
        end

        context '#split payment inserted and amount is updated for last payment' do
          before do
            allow(order).to receive(:has_checkout_step?).and_return(true)
            allow(order).to receive(:payment?).and_return(true)
          end

          it { expect(order).to receive(:update_attributes).with({
            "payments_attributes" => [
              {"amount"=>10, "payment_method_id"=>"1", "is_partial"=>true},
              {"amount"=>90, "payment_method_id"=>"1"}
            ]}).and_return(false) }
        end
      end

      after do
        send_request(
          order: {
            split_payments: [{ payment_method_id: '1' }],
            payments_attributes: [{ payment_method_id: '1' }]},
          state: 'payment')
      end
    end
  end

  describe '#object_params' do
    def send_request(params = {})
      put :update, params.merge!(use_route: 'spree')
    end
    before do
      allow(order).to receive(:has_checkout_step?).and_return(true)
      allow(order).to receive(:payment?).and_return(true)
    end

    it { expect(order).to receive(:outstanding_balance).and_return(order.total) }

    after do
      send_request(
        order: {
          payments_attributes: [{ payment_method_id: '1' }] },
        state: 'payment')
    end
  end
end
