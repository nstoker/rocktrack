class AddGiftedToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :gifted, :boolean, default: false
  end
end
