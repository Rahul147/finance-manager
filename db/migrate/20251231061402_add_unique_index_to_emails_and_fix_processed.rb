class AddUniqueIndexToEmailsAndFixProcessed < ActiveRecord::Migration[8.1]
  def change
    add_index :emails, [ :email_account_id, :message_id ], unique: true

    change_column_null :emails, :processed, false
    change_column_default :emails, :processed, false
  end
end
