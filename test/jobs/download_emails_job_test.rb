require "test_helper"

class DownloadEmailsJobTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @email_account = email_accounts(:one)
  end

  test "raises RecordNotFound for invalid user_id" do
    assert_raises(ActiveRecord::RecordNotFound) do
      DownloadEmailsJob.new.perform(999999)
    end
  end

  test "uses default queue" do
    assert_equal "default", DownloadEmailsJob.new.queue_name
  end

  test "can be enqueued with parameters" do
    assert_enqueued_with(
      job: DownloadEmailsJob,
      args: [ @user.id, { days: 7, max: 100 } ]
    ) do
      DownloadEmailsJob.perform_later(@user.id, days: 7, max: 100)
    end
  end

  test "default_senders includes expected bank addresses" do
    job = DownloadEmailsJob.new
    senders = job.send(:default_senders)

    assert_includes senders, "alerts@axisbank.com"
    assert_includes senders, "alerts@hdfcbank.net"
    assert_includes senders, "credit_cards@icicibank.com"
    assert_includes senders, "onlinesbicard@sbicard.com"
  end

  # Note: Tests that require mocking GoogleGmail are skipped in vanilla Rails testing.
  # Integration tests with real Gmail API calls require proper OAuth credentials
  # and should be done in a separate integration test suite.
end
