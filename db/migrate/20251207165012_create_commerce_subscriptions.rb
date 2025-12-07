class CreateCommerceSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: { to_table: :commerce_products }
      t.references :purchase, null: false, foreign_key: { to_table: :commerce_purchases }
      t.references :price, null: false, foreign_key: { to_table: :commerce_prices }
      t.references :payment_method, foreign_key: { to_table: :commerce_payment_methods }
      t.string :processor_customer_id
      t.string :processor_subscription_id
      t.integer :status, default: 0
      t.datetime :current_period_end
      t.datetime :cancellation_date
      t.text :cancellation_reason

      t.timestamps
    end
  end
end
