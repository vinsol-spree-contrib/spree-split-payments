require 'spec_helper'

describe Spree::Order do
  let(:order) { Spree::Order.create! }

  describe 'process_partial_payments' do
    before do
      @payment = order.payments.build
      @payments = [@payment]
      allow(order).to receive(:payments).and_return(@payments)
      allow(@payments).to receive(:pending).and_return(@payments)
      allow(@payments).to receive(:partial).and_return(@payments)
    end

    it { expect(@payments).to receive(:pending).and_return(@payments) }
    it { expect(@payments).to receive(:partial).and_return(@payments) }
    it { expect(@payment).to receive(:complete).and_return(true) }

    after { order.process_partial_payments }
  end

  context 'state machine' do
    before do
    end

    it { expect(order).to receive(:process_partial_payments).and_return(true) }

    after do 
      order.state = 'complete'
      order.save
    end
  end
end