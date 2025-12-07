class CreateCommerceProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_products do |t|
      t.string :name
      t.string :slug
      t.string :processor_product_id
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
