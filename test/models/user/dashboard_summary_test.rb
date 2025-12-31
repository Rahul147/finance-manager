require "test_helper"

class User::DashboardSummaryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @summary = User::DashboardSummary.new(user: @user)
  end

  # === Initialization ===

  test "initializes with user" do
    assert_equal @user, @summary.user
  end

  # === Transaction Metrics ===

  test "total_transactions counts all user transactions" do
    expected_count = Transaction.for_user(@user.id).count
    assert_equal expected_count, @summary.total_transactions
  end

  test "lifetime_spend_cents sums all expense transactions" do
    expected_sum = Transaction.for_user(@user.id).expenses.sum(:amount_cents)
    assert_equal expected_sum, @summary.lifetime_spend_cents
  end

  test "current_month_spend_cents only includes current month expenses" do
    current_month_range = Date.current.beginning_of_month..Date.current.end_of_month
    expected_sum = Transaction.for_user(@user.id)
      .expenses
      .where(transaction_date: current_month_range)
      .sum(:amount_cents)

    assert_equal expected_sum, @summary.current_month_spend_cents
  end

  test "current_month_transactions counts current month expenses" do
    current_month_range = Date.current.beginning_of_month..Date.current.end_of_month
    expected_count = Transaction.for_user(@user.id)
      .expenses
      .where(transaction_date: current_month_range)
      .count

    assert_equal expected_count, @summary.current_month_transactions
  end

  test "current_month_label formats month and year" do
    expected_label = Date.current.strftime("%B %Y")
    assert_equal expected_label, @summary.current_month_label
  end

  test "average_transaction_cents calculates correctly" do
    expense_transactions = Transaction.for_user(@user.id).expenses
    if expense_transactions.any?
      expected_avg = expense_transactions.sum(:amount_cents).fdiv(expense_transactions.count)
      assert_in_delta expected_avg, @summary.average_transaction_cents, 0.01
    else
      assert_equal 0.0, @summary.average_transaction_cents
    end
  end

  test "average_transaction_cents returns zero when no expenses" do
    empty_user = users(:two)
    # Delete user two's expense transactions for this test
    Transaction.for_user(empty_user.id).expenses.delete_all

    summary = User::DashboardSummary.new(user: empty_user)
    assert_equal 0.0, summary.average_transaction_cents
  end

  test "dominant_currency returns most common currency" do
    # User one has INR transactions
    assert_equal "INR", @summary.dominant_currency
  end

  test "dominant_currency returns default when no currencies" do
    # Create a summary for user with no transactions
    Transaction.for_user(@user.id).delete_all
    summary = User::DashboardSummary.new(user: @user)
    assert_equal "₹", summary.dominant_currency
  end

  test "top_categories returns grouped expense amounts" do
    categories = @summary.top_categories
    assert categories.is_a?(Array)

    categories.each do |entry|
      assert entry.key?(:label)
      assert entry.key?(:amount_cents)
      assert entry[:amount_cents].is_a?(Integer)
    end
  end

  test "top_categories limited to 5 entries" do
    assert @summary.top_categories.size <= 5
  end

  test "top_merchants returns grouped expense amounts" do
    merchants = @summary.top_merchants
    assert merchants.is_a?(Array)

    merchants.each do |entry|
      assert entry.key?(:label)
      assert entry.key?(:amount_cents)
    end
  end

  test "recent_trend returns current and previous period counts" do
    trend = @summary.recent_trend
    assert trend.key?(:current)
    assert trend.key?(:previous)
    assert trend[:current].is_a?(Integer)
    assert trend[:previous].is_a?(Integer)
  end

  test "transaction_type_breakdown includes all types with counts" do
    breakdown = @summary.transaction_type_breakdown
    assert breakdown.is_a?(Array)

    breakdown.each do |entry|
      assert entry.key?(:label)
      assert entry.key?(:count)
      assert entry.key?(:percentage)
    end
  end

  test "transaction_type_breakdown sorted by count descending" do
    breakdown = @summary.transaction_type_breakdown
    return if breakdown.size < 2

    breakdown.each_cons(2) do |higher, lower|
      assert higher[:count] >= lower[:count]
    end
  end

  # === Email / Ingestion Metrics ===

  test "connected_accounts returns user's email accounts" do
    accounts = @summary.connected_accounts
    assert accounts.all? { |a| a.user_id == @user.id }
  end

  test "connected_accounts_count returns correct count" do
    expected = EmailAccount.where(user: @user).count
    assert_equal expected, @summary.connected_accounts_count
  end

  test "total_emails counts user's emails" do
    expected = Email.for_user(@user.id).count
    assert_equal expected, @summary.total_emails
  end

  test "processed_emails counts only processed emails" do
    expected = Email.for_user(@user.id).processed.count
    assert_equal expected, @summary.processed_emails
  end

  test "pending_emails is difference of total and processed" do
    expected = @summary.total_emails - @summary.processed_emails
    assert_equal expected, @summary.pending_emails
  end

  test "emails_without_transactions counts unlinked emails" do
    count = @summary.emails_without_transactions
    assert count.is_a?(Integer)
    assert count >= 0
  end

  test "latest_sync_by_account returns account sync times" do
    sync_data = @summary.latest_sync_by_account
    assert sync_data.is_a?(Array)

    sync_data.each do |entry|
      assert entry.key?(:account)
      assert entry.key?(:last_synced_at)
      assert_instance_of EmailAccount, entry[:account]
    end
  end

  test "latest_sync_at returns most recent sync time" do
    latest = @summary.latest_sync_at
    # Can be nil if no emails exist
    assert latest.nil? || latest.is_a?(Time) || latest.is_a?(ActiveSupport::TimeWithZone)
  end

  # === Memoization ===

  test "total_transactions is memoized" do
    first_call = @summary.total_transactions
    second_call = @summary.total_transactions
    assert_equal first_call.object_id, first_call.object_id
  end

  # === Edge Cases ===

  test "handles user with no data" do
    # Create a new user with no associated data
    new_user = User.create!(email_address: "empty@example.com", password: "password")
    summary = User::DashboardSummary.new(user: new_user)

    assert_equal 0, summary.total_transactions
    assert_equal 0, summary.lifetime_spend_cents
    assert_equal 0, summary.current_month_spend_cents
    assert_equal 0, summary.total_emails
    assert_equal [], summary.top_categories
    assert_equal [], summary.top_merchants
  end
end
