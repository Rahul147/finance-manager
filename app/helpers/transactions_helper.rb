module TransactionsHelper
  STATUS_COLOR_MAP = {
    "posted" => "bg-emerald-300 text-emerald-900",
    "completed" => "bg-emerald-300 text-emerald-900",
    "pending" => "bg-yellow-300 text-yellow-900",
    "failed" => "bg-rose-300 text-rose-900",
    "refunded" => "bg-sky-300 text-sky-900",
    :default => "bg-slate-200 text-slate-800"
  }.freeze

  def transaction_status_styles(status)
    STATUS_COLOR_MAP[status.to_s.downcase] || STATUS_COLOR_MAP[:default]
  end

  def transaction_amount_display(transaction)
    return "—" if transaction.amount_cents.blank?

    unit = transaction.currency.presence || "₹"
    number_to_currency(transaction.amount_cents / 100.0, unit: unit, format: "%u %n")
  end
end
