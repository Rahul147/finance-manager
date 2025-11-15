class AddIndexesToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions, :email_id, name: "index_transactions_on_email_id", if_not_exists: true
    add_index :transactions, :user_id,  name: "index_transactions_on_user_id",  if_not_exists: true
  end
end
