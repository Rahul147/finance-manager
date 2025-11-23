class TransactionMetrics
  DEFAULT_CURRENCY = "₹".freeze
  UNLABELED_STATUS = "Unlabeled".freeze

  def initialize(relation)
    @relation = relation
  end

  def total
    @total ||= relation.count
  end

  def total_amount_cents
    expense_amount_cents
  end

  def average_amount_cents
    return 0 if expense_total.zero?

    expense_amount_cents.fdiv(expense_total)
  end

  def dominant_currency
    @dominant_currency ||= expense_relation
      .where.not(currency: [ nil, "" ])
      .group(:currency)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .count
      .keys
      .first || DEFAULT_CURRENCY
  end

  def unique_merchants
    @unique_merchants ||= expense_relation
      .where.not(merchant: [ nil, "" ])
      .distinct
      .count(:merchant)
  end

  def linked_email_count
    @linked_email_count ||= relation.where.not(email_id: nil).count
  end

  def linked_email_percentage
    percentage(linked_email_count)
  end

  def status_counts(limit = nil)
    counts = relation.group(:status).count

    normalized_counts = counts.each_with_object(Hash.new(0)) do |(status, count), acc|
      label = status.present? ? status : UNLABELED_STATUS
      acc[label] += count
    end

    sorted = normalized_counts.sort_by { |_, count| -count }
    limit ? sorted.first(limit) : sorted
  end

  def type_counts(limit = nil)
    counts = relation.group(:transaction_type).count

    entries = counts.map do |raw_value, count|
      normalized = normalized_transaction_type_key(raw_value)
      label = if normalized.present?
        Transaction::TRANSACTION_TYPE_LABELS[normalized.to_sym] || normalized.titleize
      else
        "Unknown"
      end

      {
        label: label,
        count: count,
        key: normalized
      }
    end

    sorted = entries.sort_by { |entry| -entry[:count] }
    limit ? sorted.first(limit) : sorted
  end

  def expense_total
    @expense_total ||= expense_relation.count
  end

  private

  attr_reader :relation

  def expense_amount_cents
    @expense_amount_cents ||= expense_relation.sum(:amount_cents).to_i
  end

  def expense_relation
    @expense_relation ||= relation.where(transaction_type: Transaction.transaction_types[:expense])
  end

  def normalized_transaction_type_key(value)
    return value if value.is_a?(String) && value.present?

    Transaction.transaction_types.key(value)
  end

  def percentage(value)
    return 0 if total.zero?

    ((value.to_f / total) * 100).round
  end
end
