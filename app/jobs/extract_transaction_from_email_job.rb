class ExtractTransactionFromEmailJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info("[ExtractTransactionFromEmailJob] running")

    email_id = args.first
    raise ArgumentError, "missing email_id" unless email_id

    email = Email.find(email_id)
    Rails.logger.info("ExtractTransactionFromEmailJob email_id=#{email_id} subject=#{email.subject.inspect}")

    transaction = TransactionExtractor.extract!(email)
    email.update!(processed: true) if transaction.present?

    Rails.logger.info("ExtractTransactionFromEmailJob done email_id=#{email_id}")
  rescue => e
    Rails.logger.error(
      "ExtractTransactionFromEmailJob failed id=#{args.first.inspect} error=#{e.class}: #{e.message}\n" \
      "#{Array(e.backtrace).first(5).join("\n")}"
    )
    raise
  end
end
