class AddPartialPaymentFieldsToSpreePaymentMethod < ActiveRecord::Migration
  def change
    add_column :spree_payment_methods, :for_partial, :boolean, default: false
    add_column :spree_payment_methods, :partial_priority, :integer, default: 0
  end
end
