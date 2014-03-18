Spree::User.class_eval do
  # alias_method :loyalty_points_for_partial_payments, :loyalty_points_equivalent_currency
  def maximum_partial_payment_for_payment_method(payment_method)
    send((payment_method.class.name.demodulize.underscore + '_for_partial_payments').to_sym)
  end
end