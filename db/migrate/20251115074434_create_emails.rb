class CreateEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :emails do |t|
      t.references :user, null: false, foreign_key: true
      t.references :email_account, null: false, foreign_key: true
      t.string :message_id
      t.string :thread_id
      t.string :subject
      t.string :from_address
      t.string :to_address
      t.datetime :sent_at
      t.text :snippet
      t.text :body_text
      t.text :body_html
      t.text :headers
      t.boolean :processed

      t.timestamps
    end
  end
end
