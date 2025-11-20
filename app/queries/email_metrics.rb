class EmailMetrics
  def initialize(relation)
    @relation = relation
  end

  def total
    @total ||= relation.count
  end

  def processed
    @processed ||= relation.processed.count
  end

  def pending
    total - processed
  end

  def processed_percentage
    percentage(processed)
  end

  def linked_transactions
    @linked_transactions ||= relation.joins(:financial_transaction).count
  end

  def linked_percentage
    percentage(linked_transactions)
  end

  def unique_senders
    @unique_senders ||= relation.where.not(from_address: [ nil, "" ]).distinct.count(:from_address)
  end

  def top_senders(limit = 4)
    @top_senders ||= relation
      .where.not(from_address: [ nil, "" ])
      .group(:from_address)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(limit)
      .count
      .to_a
  end

  def latest_activity_at
    @latest_activity_at ||= relation.maximum(Arel.sql("COALESCE(sent_at, created_at)"))
  end

  private

  attr_reader :relation

  def percentage(value)
    return 0 if total.zero?

    ((value.to_f / total) * 100).round
  end
end
