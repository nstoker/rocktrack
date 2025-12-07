class AddSubscriptionStatusToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :subscription_status, :integer, default: 0
  end
end
