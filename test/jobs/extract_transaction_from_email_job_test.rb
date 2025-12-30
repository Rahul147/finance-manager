require "test_helper"

class ExtractTransactionFromEmailJobTest < ActiveSupport::TestCase
  setup do
    @email = emails(:icici_upi)
  end

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

  test "can be enqueued" do
    assert_enqueued_with(job: ExtractTransactionFromEmailJob, args: [ @email.id ]) do
      ExtractTransactionFromEmailJob.perform_later(@email.id)
    end
  end

  test "uses default queue" do
    assert_equal "default", ExtractTransactionFromEmailJob.new.queue_name
  end

  # Note: Tests that require mocking TransactionExtractor are skipped in vanilla Rails testing.
  # Integration tests with real OpenAI calls should be done sparingly or in a separate test suite.
  # The job's core functionality (finding email, calling extractor, updating processed flag)
  # is tested through the actual TransactionExtractor in service tests.
end
