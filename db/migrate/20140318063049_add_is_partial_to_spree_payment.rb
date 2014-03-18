class AddIsPartialToSpreePayment < ActiveRecord::Migration
  def change
    add_column :spree_payments, :is_partial, :boolean, :default => false
  end
end