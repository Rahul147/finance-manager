class SyncEmailsJob < ApplicationJob
  queue_as :default

  def perform(days: 1, max: 200)
    User.joins(:email_accounts).distinct.find_each do |user|
      Rails.logger.info("[SyncEmailJob] running for=#{user.email_address} days=#{days} max=#{max}")
      DownloadEmailsJob.perform_later(user.id, days: days, max: max)
    end
  end
end
