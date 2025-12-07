class CreateCommercePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_prices do |t|
      t.references :product, null: false, foreign_key: { to_table: :commerce_products }
      t.string :name
      t.string :slug
      t.string :processor_price_id
      t.integer :amount
      t.boolean :recurring, default: false
      t.integer :recurring_interval, default: 0
      t.integer :trial_days, default: 0

      t.timestamps
    end
  end
end
