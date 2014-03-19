Spree::Payment.class_eval do
  after_create :complete, if: :is_partial?
end