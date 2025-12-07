class CreateCommercePlanBenefits < ActiveRecord::Migration[8.0]
  def change
    create_table :commerce_plan_benefits do |t|
      t.references :plan, null: false, foreign_key: { to_table: :commerce_plans }
      t.references :benefit, null: false, foreign_key: { to_table: :commerce_benefits }
      t.integer :position, default: 1

      t.timestamps
    end
  end
end
