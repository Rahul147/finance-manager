class Transaction < ApplicationRecord
  include Categorizable

  belongs_to :user
  belongs_to :email

  scope :expenses, -> { where(transaction_type: transaction_types[:expense]) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :ordered_newest, -> { order(transaction_date: :desc, created_at: :desc) }
  scope :search, lambda { |raw_query|
    query = raw_query.to_s.strip
    if query.blank?
      all
    else
      query_downcased = query.downcase
      sanitized = ApplicationRecord.sanitize_sql_like(query_downcased)
      pattern = "%#{sanitized}%"
      matching_category_keys = CATEGORY_LIST
        .select { |_key, label| label.downcase.include?(query_downcased) }
        .keys
        .map(&:to_s)

      sql = "LOWER(merchant) LIKE :pattern OR LOWER(category) LIKE :pattern OR LOWER(notes) LIKE :pattern"
      bindings = { pattern: pattern }

      if matching_category_keys.any?
        sql = "#{sql} OR category IN (:matching_category_keys)"
        bindings[:matching_category_keys] = matching_category_keys
      end

      where(sql, bindings)
    end
  }
end
