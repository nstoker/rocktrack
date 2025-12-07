class CreateCommercePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_payments do |t|
      t.references :account, null: false, foreign_key: true
      t.string :currency
      t.references :payment_method, foreign_key: { to_table: :commerce_payment_methods }
      t.references :subscription, foreign_key: { to_table: :commerce_subscriptions }
      t.references :purchase, foreign_key: { to_table: :commerce_purchases }
      t.string :processor_payment_id
      t.string :processor_customer_id
      t.string :processor_invoice_id
      t.integer :amount
      t.integer :status, default: 0
      t.string :resolve_token

      t.timestamps
    end
  end
end
