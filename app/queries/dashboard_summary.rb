class DashboardSummary
  DEFAULT_CURRENCY = "₹".freeze
  TOP_LIMIT = 5

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  # === Transaction metrics ===

  def total_transactions
    @total_transactions ||= transactions_scope.count
  end

  def lifetime_spend_cents
    @lifetime_spend_cents ||= expense_transactions_scope.sum(:amount_cents).to_i
  end

  def current_month_spend_cents
    @current_month_spend_cents ||= expense_transactions_scope
      .where(transaction_date: current_month_range)
      .sum(:amount_cents)
      .to_i
  end

  def current_month_transactions
    @current_month_transactions ||= expense_transactions_scope
      .where(transaction_date: current_month_range)
      .count
  end

  def current_month_label
    @current_month_label ||= current_month_range.begin.strftime("%B %Y")
  end

  def average_transaction_cents
    expense_count = expense_transactions_scope.count
    return 0.0 if expense_count.zero?

    lifetime_spend_cents.fdiv(expense_count)
  end

  def dominant_currency
    @dominant_currency ||= begin
      transactions_scope
        .where.not(currency: [ nil, "" ])
        .group(:currency)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(1)
        .count
        .keys
        .first || DEFAULT_CURRENCY
    end
  end

  def top_categories
    @top_categories ||= grouped_amounts(
      expense_transactions_scope
        .where(transaction_date: current_month_range)
        .where.not(category: [ nil, "" ]),
      :category
    )
  end

  def top_merchants
    @top_merchants ||= grouped_amounts(
      expense_transactions_scope
        .where(transaction_date: rolling_30_day_range)
        .where.not(merchant: [ nil, "" ]),
      :merchant
    )
  end

  def recent_trend
    @recent_trend ||= {
      current: expense_transactions_scope.where(transaction_date: recent_7_day_range).count,
      previous: expense_transactions_scope.where(transaction_date: previous_7_day_range).count
    }
  end

  def transaction_type_breakdown
    @transaction_type_breakdown ||= begin
      counts = transactions_scope.group(:transaction_type).count

      counts.map do |raw_value, count|
        key = normalized_transaction_type_key(raw_value)
        label = if key.present?
          Transaction::TRANSACTION_TYPE_LABELS[key.to_sym] || key.titleize
        else
          "Unknown"
        end

        {
          label: label,
          count: count,
          percentage: percentage(count)
        }
      end.sort_by { |entry| -entry[:count] }
    end
  end

  # === Email / ingestion metrics ===

  def connected_accounts
    @connected_accounts ||= user.email_accounts.order(:email_address).load
  end

  def connected_accounts_count
    connected_accounts.size
  end

  def total_emails
    @total_emails ||= emails_scope.count
  end

  def processed_emails
    @processed_emails ||= emails_scope.processed.count
  end

  def pending_emails
    total_emails - processed_emails
  end

  def emails_without_transactions
    @emails_without_transactions ||= emails_scope
      .left_outer_joins(:financial_transaction)
      .where(transactions: { id: nil })
      .count
  end

  def latest_sync_by_account
    @latest_sync_by_account ||= begin
      converted_timestamps = timestamps_by_account

      connected_accounts.map do |account|
        {
          account: account,
          last_synced_at: converted_timestamps[account.id]
        }
      end
    end
  end

  def latest_sync_at
    @latest_sync_at ||= timestamps_by_account.values.compact.max
  end

  private

  def percentage(value)
    return 0 if total_transactions.zero?

    ((value.to_f / total_transactions) * 100).round
  end

  def grouped_amounts(scope, column)
    scope
      .group(column)
      .order(Arel.sql("SUM(amount_cents) DESC"))
      .limit(TOP_LIMIT)
      .sum(:amount_cents)
      .map do |label, amount|
        {
          label: label.presence || "Uncategorized",
          amount_cents: amount.to_i
        }
      end
  end

  def timestamps_by_account
    @timestamps_by_account ||= begin
      raw = emails_scope
        .group(:email_account_id)
        .maximum(Arel.sql("COALESCE(sent_at, created_at)"))

      raw.transform_values { |value| coerce_time(value) }
    end
  end

  def transactions_scope
    @transactions_scope ||= Transaction.for_user(user.id)
  end

  def expense_transactions_scope
    @expense_transactions_scope ||= transactions_scope.where(transaction_type: Transaction.transaction_types[:expense])
  end

  def normalized_transaction_type_key(value)
    return value if value.is_a?(String) && value.present?

    Transaction.transaction_types.key(value)
  end

  def emails_scope
    @emails_scope ||= Email.for_user(user.id)
  end

  def current_month_range
    @current_month_range ||= begin
      today = Time.zone.today
      today.beginning_of_month..today.end_of_month
    end
  end

  def rolling_30_day_range
    @rolling_30_day_range ||= (30.days.ago.to_date..Date.current)
  end

  def recent_7_day_range
    @recent_7_day_range ||= (7.days.ago.to_date..Date.current)
  end

  def previous_7_day_range
    @previous_7_day_range ||= begin
      end_date = recent_7_day_range.first - 1.day
      (end_date - 6.days)..end_date
    end
  end

  def coerce_time(value)
    return if value.blank?
    return value if value.is_a?(ActiveSupport::TimeWithZone) || value.is_a?(Time) || value.is_a?(DateTime)
    return value.to_time if value.respond_to?(:to_time)

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
