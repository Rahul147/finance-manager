class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :email

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :ordered_newest, -> { order(transaction_date: :desc, created_at: :desc) }
  scope :search, lambda { |raw_query|
    query = raw_query.to_s.strip
    if query.blank?
      all
    else
      sanitized = ApplicationRecord.sanitize_sql_like(query.downcase)
      pattern = "%#{sanitized}%"

      where(
        "LOWER(merchant) LIKE :pattern OR LOWER(category) LIKE :pattern OR LOWER(notes) LIKE :pattern",
        pattern: pattern
      )
    end
  }
end
