class RenameEmailToEmailAddressInEmailAccounts < ActiveRecord::Migration[8.1]
  def change
    rename_column :email_accounts, :email, :email_address
  end
end
