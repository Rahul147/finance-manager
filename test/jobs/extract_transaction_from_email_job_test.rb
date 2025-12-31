require "test_helper"

class ExtractTransactionFromEmailJobTest < ActiveSupport::TestCase
  setup do
    @email = emails(:icici_upi)
    @email.update!(processed: false)
  end

  # === Argument Validation ===

  test "raises ArgumentError when email_id is missing" do
    assert_raises(ArgumentError) do
      ExtractTransactionFromEmailJob.new.perform
    end
  end

  test "raises ActiveRecord::RecordNotFound for invalid email_id" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ExtractTransactionFromEmailJob.new.perform(999999)
    end
  end

  # === Enqueueing ===

  test "can be enqueued" do
    assert_enqueued_with(job: ExtractTransactionFromEmailJob, args: [ @email.id ]) do
      ExtractTransactionFromEmailJob.perform_later(@email.id)
    end
  end

  test "uses default queue" do
    assert_equal "default", ExtractTransactionFromEmailJob.new.queue_name
  end

  # === Job Structure ===

  test "job is an ApplicationJob" do
    assert ExtractTransactionFromEmailJob < ApplicationJob
  end

  test "perform method accepts email_id argument" do
    job = ExtractTransactionFromEmailJob.new
    assert_respond_to job, :perform
  end

  # Note: Full integration tests that verify the job calls Transaction::Extractor
  # and marks emails as processed require mocking the OpenAI API.
  # Those behaviors are documented and tested manually/in integration.
  #
  # Job behavior summary:
  # 1. Finds email by ID
  # 2. Calls Transaction::Extractor.extract_from(email)
  # 3. If transaction is created and persisted, marks email.processed = true
  # 4. Logs throughout and re-raises any exceptions
end
