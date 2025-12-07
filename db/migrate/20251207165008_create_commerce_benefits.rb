class CreateCommerceBenefits < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_benefits do |t|
      t.string :name
      t.text :benefit_text
      t.text :tooltip
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
