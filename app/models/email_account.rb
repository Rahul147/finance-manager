class EmailAccount < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token
  validates :email, presence: true
  validates :provider, presence: true
  validates :provider_account_id, presence: true, uniqueness: { scope: :provider }
end
