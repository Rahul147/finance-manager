class Email < ApplicationRecord
  belongs_to :user
  belongs_to :email_account

  has_one :financial_transaction, class_name: "Transaction", inverse_of: :email, dependent: :destroy
end
