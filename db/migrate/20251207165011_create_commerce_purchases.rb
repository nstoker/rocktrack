class CreateCommercePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_purchases do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: { to_table: :commerce_products }
      t.references :price, null: false, foreign_key: { to_table: :commerce_prices }
      t.references :payment_method, foreign_key: { to_table: :commerce_payment_methods }
      t.string :processor_customer_id

      t.timestamps
    end
  end
end
