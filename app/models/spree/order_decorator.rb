Spree::Order.class_eval do
  Spree::Order.state_machine.before_transition :to => :complete, :do => :process_partial_payments

  def process_partial_payments
    self.payments.pending.partial.each { |payment| payment.complete }
  end
end
