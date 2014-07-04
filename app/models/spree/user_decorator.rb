Spree::User.class_eval do
  # alias should be defined in the app integrating partial payments with
  # any other payment method
  # for example for Spree::LoyaltyPoints has a method for user to calculate
  # amount quivalent to points as loyalty_points_equivalent_currency, so we do
  # alias_method :loyalty_points_for_partial_payments,
  #              :loyalty_points_equivalent_currency

  def maximum_partial_payment_for_payment_method(payment_method)
    max_amount_method = "#{payment_method.class.name.demodulize.underscore}_for_partial_payments"
    if respond_to? max_amount_method
      send max_amount_method
    else
      Float::INFINITY
    end
    # send(
    #   "#{payment_method.class.name.demodulize.underscore}_for_partial_payments"
    #   .to_sym)
  end
end
