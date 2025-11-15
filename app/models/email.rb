class Email < ApplicationRecord
  belongs_to :user
  belongs_to :email_account
end
