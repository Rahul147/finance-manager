class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.integer :amount_cents
      t.string :category
      t.string :currency
      t.string :merchant
      t.text :metadata
      t.text :notes
      t.string :status
      t.date :transaction_date
      t.references :user, null: false, foreign_key: true
      t.references :email, null: false, foreign_key: true

      t.timestamps
    end
  end
end
