require "test_helper"

class SyncEmailsJobTest < ActiveSupport::TestCase
  setup do
    @user_with_account = users(:one)
  end

  test "enqueues DownloadEmailsJob for users with email accounts" do
    assert_enqueued_with(job: DownloadEmailsJob) do
      SyncEmailsJob.new.perform
    end
  end

  test "passes default days and max parameters" do
    assert_enqueued_with(
      job: DownloadEmailsJob,
      args: [ @user_with_account.id, { days: 1, max: 200 } ]
    ) do
      SyncEmailsJob.new.perform
    end
  end

  test "respects custom days parameter" do
    assert_enqueued_with(
      job: DownloadEmailsJob,
      args: [ @user_with_account.id, { days: 7, max: 200 } ]
    ) do
      SyncEmailsJob.new.perform(days: 7)
    end
  end

  test "respects custom max parameter" do
    assert_enqueued_with(
      job: DownloadEmailsJob,
      args: [ @user_with_account.id, { days: 1, max: 50 } ]
    ) do
      SyncEmailsJob.new.perform(max: 50)
    end
  end

  test "uses default queue" do
    assert_equal "default", SyncEmailsJob.new.queue_name
  end

  test "can be enqueued" do
    assert_enqueued_with(job: SyncEmailsJob) do
      SyncEmailsJob.perform_later
    end
  end

  test "only processes users with email accounts" do
    # Create a user without email accounts
    user_without = User.create!(
      email_address: "noaccounts@example.com",
      password: "password"
    )

    # Count users with email accounts
    users_with_accounts = User.joins(:email_accounts).distinct.count

    # Job should enqueue exactly that many DownloadEmailsJobs
    assert_enqueued_jobs users_with_accounts, only: DownloadEmailsJob do
      SyncEmailsJob.new.perform
    end
  end
end
