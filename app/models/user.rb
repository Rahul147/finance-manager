class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :email_accounts, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :transactions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
