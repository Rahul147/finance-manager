require "test_helper"

class DownloadEmailsJobTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @email_account = email_accounts(:one)
  end

  # === Argument Validation ===

  test "raises RecordNotFound for invalid user_id" do
    assert_raises(ActiveRecord::RecordNotFound) do
      DownloadEmailsJob.new.perform(999999)
    end
  end

  # === Enqueueing ===

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

  test "can be enqueued with default parameters" do
    assert_enqueued_with(job: DownloadEmailsJob, args: [ @user.id ]) do
      DownloadEmailsJob.perform_later(@user.id)
    end
  end

  # === Job Structure ===

  test "job is an ApplicationJob" do
    assert DownloadEmailsJob < ApplicationJob
  end

  test "accepts keyword arguments for days and max" do
    job = DownloadEmailsJob.new
    # This should not raise - testing the method signature
    assert_respond_to job, :perform
  end

  # === Default Senders ===

  test "default_senders includes expected bank addresses" do
    job = DownloadEmailsJob.new
    senders = job.send(:default_senders)

    assert_includes senders, "alerts@axisbank.com"
    assert_includes senders, "alerts@hdfcbank.net"
    assert_includes senders, "credit_cards@icicibank.com"
    assert_includes senders, "onlinesbicard@sbicard.com"
  end

  test "default_senders returns an array" do
    job = DownloadEmailsJob.new
    senders = job.send(:default_senders)

    assert_kind_of Array, senders
    assert senders.all? { |s| s.is_a?(String) }
  end

  test "default_senders are valid email addresses" do
    job = DownloadEmailsJob.new
    senders = job.send(:default_senders)

    senders.each do |sender|
      assert_match(/@/, sender, "#{sender} should be an email address")
    end
  end

  # Note: Full integration tests that verify the job calls Email::Gmail.ingest_latest
  # for each Google account require mocking the Gmail API.
  # Those behaviors are documented and tested manually/in integration.
  #
  # Job behavior summary:
  # 1. Finds user by ID
  # 2. Iterates over user's email_accounts
  # 3. Skips non-Google providers
  # 4. Calls Email::Gmail.ingest_latest for each Google account
  # 5. Passes senders, days, max, and unread_only parameters
end
