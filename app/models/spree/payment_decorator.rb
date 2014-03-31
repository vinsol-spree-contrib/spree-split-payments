Spree::Payment.class_eval do
  after_create :mark_pending_if_partial, if: :is_partial?

  def self.partial
    where(is_partial: true)
  end

  private

  def mark_pending_if_partial
    self.pend
  end
end