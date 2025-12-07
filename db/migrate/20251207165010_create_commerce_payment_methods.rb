class CreateCommercePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_payment_methods do |t|
      t.references :account, null: false, foreign_key: true
      t.string :processor_customer_id
      t.string :processor_payment_method_id
      t.integer :brand
      t.string :last4
      t.integer :expiration_month
      t.integer :expiration_year
      t.boolean :default, default: false

      t.timestamps
    end
  end
end
