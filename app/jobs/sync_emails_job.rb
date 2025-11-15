class SyncEmailsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info("[SyncEmailJob] running at=#{Time.current} accounts=#{EmailAccount.count}")
    # Do something later
  end
end
