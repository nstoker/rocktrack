class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.belongs_to :owner, foreign_key: { to_table: :users }
      t.string :slug

      t.timestamps
    end
  end
end
