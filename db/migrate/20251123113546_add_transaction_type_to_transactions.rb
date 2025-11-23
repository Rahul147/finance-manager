class AddTransactionTypeToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :transaction_type, :integer, null: false, default: 0
    add_index :transactions, :transaction_type
  end
end
