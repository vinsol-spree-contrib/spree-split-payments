require 'spec_helper'

describe Spree::CheckoutController do
  let(:user) { mock_model(Spree.user_class) }
  let(:order) { Spree::Order.new }
  let(:payment) { mock_model(Spree::Payment) }
  let(:variant) { mock_model(Spree::Variant, :name => 'test-variant') }

  before(:each) do
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
      it { Spree::PaymentMethod.should_receive(:where).with(:id => '1').and_return(@payment_method) }
      after { send_request({"order"=>{"split_payments" => [{'payment_method_id' => '1'}], "payments_attributes"=>[{"payment_method_id"=>"2"}]}, "state"=>"payment"}) }
    end
  end
end