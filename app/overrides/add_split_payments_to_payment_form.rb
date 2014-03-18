Deface::Override.new(
  :virtual_path => 'spree/checkout/_payment',
  :name => 'add split payments to payment form',
  :insert_top => '#payment-method-fields',
  :partial => 'shared/split_payments')