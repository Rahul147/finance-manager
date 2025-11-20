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
    @total_amount_cents ||= relation.sum(:amount_cents).to_i
  end

  def average_amount_cents
    return 0 if total.zero?

    total_amount_cents.fdiv(total)
  end

  def dominant_currency
    @dominant_currency ||= relation
      .where.not(currency: [ nil, "" ])
      .group(:currency)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .count
      .keys
      .first || DEFAULT_CURRENCY
  end

  def unique_merchants
    @unique_merchants ||= relation
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

  private

  attr_reader :relation

  def percentage(value)
    return 0 if total.zero?

    ((value.to_f / total) * 100).round
  end
end

