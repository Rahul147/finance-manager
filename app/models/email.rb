class Email < ApplicationRecord
  belongs_to :user
  belongs_to :email_account

  has_one :financial_transaction, class_name: "Transaction", inverse_of: :email, dependent: :destroy

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :processed, -> { where(processed: true) }
  scope :ordered_newest, -> { order(sent_at: :desc, created_at: :desc) }
  scope :search, lambda { |raw_query|
    query = raw_query.to_s.strip
    if query.blank?
      all
    else
      sanitized = ApplicationRecord.sanitize_sql_like(query.downcase)
      pattern = "%#{sanitized}%"

      where(
        "LOWER(subject) LIKE :pattern OR LOWER(from_address) LIKE :pattern OR LOWER(snippet) LIKE :pattern",
        pattern: pattern
      )
    end
  }
end
