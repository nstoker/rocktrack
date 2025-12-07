class CreateInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :invitations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :created_by_user, foreign_key: { to_table: :users }, null: false
      t.string :email, null: false
      t.string :token, null: false
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
