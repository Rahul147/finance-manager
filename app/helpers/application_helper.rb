module ApplicationHelper
  def google_connected?
    return false unless Current.user
    Current.user.email_accounts.where.not(refresh_token: [nil, ""]).exists?
  end
end