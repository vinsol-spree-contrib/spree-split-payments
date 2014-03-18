require 'spec_helper'

describe 'Spree::Payment' do
  let(:order) { Spree::Order.create! }
  context 'after create callback' do
    before do
      @payment = order.payments.new(:is_partial => true)
      allow(@payment).to receive(:complete).and_return(true)
    end

    it 'calls for complete on save' do
      expect(@payment).to receive(:complete).and_return(true)
      @payment.save!
    end
  end
end