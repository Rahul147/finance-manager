class CreateEmailAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :email_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.string :provider, null: false
      t.string :provider_account_id, null: false
      t.text :access_token
      t.text :refresh_token
      t.string :scope
      t.string :status
      t.string :token_type
      t.datetime :expires_at

      t.timestamps
    end

    add_index :email_accounts, [ :provider, :provider_account_id ], unique: true
  end
end
