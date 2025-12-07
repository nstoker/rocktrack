class CreateCommercePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_plans do |t|
      t.string :name
      t.string :display_name
      t.references :price_a, foreign_key: { to_table: :commerce_prices }
      t.string :price_a_alt_amount
      t.string :price_a_append_text
      t.string :price_a_note
      t.references :price_b, foreign_key: { to_table: :commerce_prices }
      t.string :price_b_alt_amount
      t.string :price_b_append_text
      t.string :price_b_note
      t.integer :position, default: 1
      t.string :highlight_text
      t.boolean :active, default: true
      t.text :short_description
      t.text :benefits_note
      t.string :button_purchase_label
      t.string :button_change_to_plan_label
      t.string :button_current_label
      t.string :button_support_text
      t.string :button_url

      t.timestamps
    end
  end
end
