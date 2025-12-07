class AddFirstPaymentToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_reference :commerce_purchases, :first_payment, foreign_key: { to_table: :commerce_payments }
  end
end
