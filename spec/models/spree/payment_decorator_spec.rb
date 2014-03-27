require 'spec_helper'

describe 'Spree::Payment' do
  let(:order) { Spree::Order.create! }
  context 'after create callback' do
    context 'for partial payments' do
      before do
        @payment = order.payments.new(is_partial: true)
        allow(@payment).to receive(:pend).and_return(true)
      end

      it 'calls for pend on save' do
        expect(@payment).to receive(:pend).and_return(true)
        @payment.save!
      end
    end

    context 'for non-partial payments' do
      before { @payment = order.payments.new }

      it 'calls for pend on save' do
        expect(@payment).to_not receive(:pend)
        @payment.save!
      end
    end
  end
end
