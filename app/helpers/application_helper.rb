module ApplicationHelper
  def google_connected?
    return false unless Current.user
    Current.user.email_accounts.where.not(refresh_token: [ nil, "" ]).exists?
  end

  def currency_amount(amount_cents, unit: "₹", placeholder: "—")
    return placeholder if amount_cents.blank?

    number_to_currency(amount_cents.to_f / 100.0, unit: unit, format: "%u %n")
  end
end
