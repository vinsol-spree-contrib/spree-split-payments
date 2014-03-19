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
    @payment_method = mock_model(Spree::PaymentMethod, :type => 'Spree::PaymentMethod::Check')
  end

  describe '#extract_partial_payments' do
    def send_request(params = {})
      put :update, params.merge!({:use_route => 'spree'})
    end

    context 'when state is not payment' do
      it { controller.should_not_receive(:extract_partial_payments) }
      after { send_request({"order"=>{"payments_attributes"=>[{"payment_method_id"=>"1"}]}, "state"=>"delivery"}) }
    end

    context 'when state is payment but without any split payment' do
      it { controller.should_not_receive(:extract_partial_payments) }
      after { send_request({"order"=>{"payments_attributes"=>[{"payment_method_id"=>"1"}]}, "state"=>"payment"}) }
    end

    context 'when state is payment and split payment attributes present' do
      context 'payment method not found' do
        it { Spree::PaymentMethod.should_receive(:where).with(:id => '1').and_return([]) }
        it { expect(user).to_not receive(:maximum_partial_payment_for_payment_method) }
      end

      context 'payment method is found' do
        before do
          allow(order).to receive(:total).and_return(100)
          allow(Spree::PaymentMethod).to receive(:where).with(:id => '1').and_return([@payment_method])
          allow(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(payment_method_partial_payment)
          @partial_payment = mock_model(Spree::Payment)
          @payments = [@partial_payment]
          allow(@partial_payment).to receive(:payment_method).and_return(@payment_method)
          allow(@payments).to receive(:completed).and_return([])
          allow(@payments).to receive(:valid).and_return([])
          allow(@payments).to receive(:create).and_return(@partial_payment)
          allow(order).to receive(:payments).and_return(@payments)
        end

        it { expect(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(payment_method_partial_payment) }
        it { Spree::PaymentMethod.should_receive(:where).with(:id => '1').and_return([@payment_method]) }
      
        context 'outstanding balance > payment_method_partial_payment' do
          it { expect(order).to receive(:outstanding_balance).and_return(order.total) }
          it { expect(@payments).to receive(:create).with(:payment_method_id => '1', :state => 'pending', amount: payment_method_partial_payment, :is_partial => true).and_return(@partial_payment) }
          
          context 'payment_method_partial_payment is 0' do
            before { allow(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(0) }
            it { expect(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(0) }
            it { expect(@payments).to_not receive(:create) }
          end
        end

        context 'outstanding balance < payment_method_partial_payment' do
          before { allow(user).to receive(:maximum_partial_payment_for_payment_method).with(@payment_method).and_return(payment_method_partial_payment + order.total) }
          it { expect(order).to receive(:outstanding_balance).and_return(order.total) }
          it { expect(@payments).to receive(:create).with(:payment_method_id => '1', :state => 'pending', amount: order.total.to_d, :is_partial => true).and_return(@partial_payment) }
        end
      end

      after { send_request({"order"=>{"split_payments" => [{'payment_method_id' => '1'}]}, "state"=>"payment"}) }
    end
  end

  describe '#object_params' do
    def send_request(params = {})
      put :update, params.merge!({:use_route => 'spree'})
    end
    before do
      allow(order).to receive(:has_checkout_step?).and_return(true)
      allow(order).to receive(:payment?).and_return(true)
    end

    it { expect(order).to receive(:outstanding_balance).and_return(order.total) }
    after { send_request({"order"=>{"payments_attributes"=>[{"payment_method_id"=>"1"}]}, "state"=>"payment"}) }
  end
end