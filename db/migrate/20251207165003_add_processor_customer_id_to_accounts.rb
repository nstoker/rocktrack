class AddProcessorCustomerIdToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :processor_customer_id, :string
  end
end
