require 'spec_helper'

describe Spree::Order do
  let(:order) { Spree::Order.create!(:email => 'test-account@myweb.com') }

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

    after { order.send(:process_partial_payments) }
  end

  context 'state machine' do
    it { Spree::Order.state_machine.callbacks[:before].select { |callback| callback.instance_eval{@methods}.include?(:process_partial_payments) && callback.branch.state_requirements.any? {|req| req[:to].values.include?(:complete)} }.should_not be_blank }
  end
end