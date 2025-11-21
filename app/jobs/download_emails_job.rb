class DownloadEmailsJob < ApplicationJob
  queue_as :default

  def perform(user_id, days: 21, max: 200)
    Rails.logger.info("[DownloadEmailsJob] running")
    user = User.find(user_id)
    user.email_accounts.find_each do |acct|
      # TODO: Add other providers
      next unless acct.provider == "google"

      GoogleGmail.ingest_latest(
        acct,
        senders: default_senders,
        days: days,
        unread_only: true,
        max: max
      )
    end
  end

  private
    def default_senders
      # TODO: This should come from the DB (configured per user?)
      %w[ alerts@axisbank.com alerts@hdfcbank.net credit_cards@icicibank.com onlinesbicard@sbicard.com ]
    end
end
