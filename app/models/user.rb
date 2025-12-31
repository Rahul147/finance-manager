class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :email_accounts, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :transactions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :email_verification, expires_in: 24.hours

  def email_verified?
    email_verified_at.present?
  end

  def mark_as_verified!
    update!(email_verified_at: Time.current)
  end
end
