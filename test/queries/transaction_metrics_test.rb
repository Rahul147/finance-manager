require "test_helper"

class TransactionMetricsTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @relation = Transaction.for_user(@user.id)
    @metrics = TransactionMetrics.new(@relation)
  end

  # === Basic Counts ===

  test "total counts all transactions in relation" do
    expected = @relation.count
    assert_equal expected, @metrics.total
  end

  test "expense_total counts only expense transactions" do
    expected = @relation.expenses.count
    assert_equal expected, @metrics.expense_total
  end

  # === Amount Calculations ===

  test "total_amount_cents sums expense amounts" do
    expected = @relation.expenses.sum(:amount_cents)
    assert_equal expected, @metrics.total_amount_cents
  end

  test "average_amount_cents calculates expense average" do
    expenses = @relation.expenses
    if expenses.any?
      expected = expenses.sum(:amount_cents).fdiv(expenses.count)
      assert_in_delta expected, @metrics.average_amount_cents, 0.01
    else
      assert_equal 0, @metrics.average_amount_cents
    end
  end

  test "average_amount_cents returns zero when no expenses" do
    empty_relation = Transaction.none
    metrics = TransactionMetrics.new(empty_relation)
    assert_equal 0, metrics.average_amount_cents
  end

  # === Currency ===

  test "dominant_currency returns most common currency" do
    assert_equal "INR", @metrics.dominant_currency
  end

  test "dominant_currency returns default when no currencies" do
    empty_metrics = TransactionMetrics.new(Transaction.none)
    assert_equal "₹", empty_metrics.dominant_currency
  end

  # === Merchant Analysis ===

  test "unique_merchants counts distinct merchants" do
    expected = @relation.expenses
      .where.not(merchant: [ nil, "" ])
      .distinct
      .count(:merchant)
    assert_equal expected, @metrics.unique_merchants
  end

  # === Email Linkage ===

  test "linked_email_count counts transactions with emails" do
    expected = @relation.where.not(email_id: nil).count
    assert_equal expected, @metrics.linked_email_count
  end

  test "linked_email_percentage calculates correctly" do
    if @metrics.total > 0
      expected = ((@metrics.linked_email_count.to_f / @metrics.total) * 100).round
      assert_equal expected, @metrics.linked_email_percentage
    else
      assert_equal 0, @metrics.linked_email_percentage
    end
  end

  test "linked_email_percentage returns zero when total is zero" do
    empty_metrics = TransactionMetrics.new(Transaction.none)
    assert_equal 0, empty_metrics.linked_email_percentage
  end

  # === Status Counts ===

  test "status_counts groups by status" do
    counts = @metrics.status_counts
    assert counts.is_a?(Array)

    counts.each do |status, count|
      assert status.is_a?(String)
      assert count.is_a?(Integer)
      assert count > 0
    end
  end

  test "status_counts normalizes nil status to Unlabeled" do
    # Create transaction without status
    transaction = transactions(:amazon_purchase)
    transaction.update_column(:status, nil)

    metrics = TransactionMetrics.new(Transaction.where(id: transaction.id))
    counts = metrics.status_counts

    assert counts.any? { |status, _| status == "Unlabeled" }
  end

  test "status_counts respects limit parameter" do
    counts_limited = @metrics.status_counts(1)
    assert counts_limited.size <= 1
  end

  # === Type Counts ===

  test "type_counts groups by transaction type" do
    counts = @metrics.type_counts
    assert counts.is_a?(Array)

    counts.each do |entry|
      assert entry.key?(:label)
      assert entry.key?(:count)
      assert entry.key?(:key)
    end
  end

  test "type_counts returns human readable labels" do
    counts = @metrics.type_counts
    labels = counts.map { |e| e[:label] }

    # Should have readable labels like "Expense", "Investment", etc.
    possible_labels = [ "Expense", "Investment", "Transfer", "Loan", "Unknown" ]
    labels.each do |label|
      assert possible_labels.include?(label), "Unexpected label: #{label}"
    end
  end

  test "type_counts sorted by count descending" do
    counts = @metrics.type_counts
    return if counts.size < 2

    counts.each_cons(2) do |higher, lower|
      assert higher[:count] >= lower[:count]
    end
  end

  test "type_counts respects limit parameter" do
    counts = @metrics.type_counts(1)
    assert counts.size <= 1
  end

  # === Filtered Relations ===

  test "works with filtered relation" do
    filtered = @relation.where(category: "groceries")
    metrics = TransactionMetrics.new(filtered)

    assert metrics.total <= @metrics.total
    assert_respond_to metrics, :total_amount_cents
    assert_respond_to metrics, :average_amount_cents
  end

  test "works with search filtered relation" do
    searched = @relation.search("Amazon")
    metrics = TransactionMetrics.new(searched)

    assert metrics.total > 0
    assert_respond_to metrics, :dominant_currency
  end

  # === Edge Cases ===

  test "handles empty relation" do
    empty_metrics = TransactionMetrics.new(Transaction.none)

    assert_equal 0, empty_metrics.total
    assert_equal 0, empty_metrics.total_amount_cents
    assert_equal 0, empty_metrics.average_amount_cents
    assert_equal 0, empty_metrics.unique_merchants
    assert_equal 0, empty_metrics.linked_email_count
    assert_equal 0, empty_metrics.linked_email_percentage
    assert_equal [], empty_metrics.status_counts
    assert_equal [], empty_metrics.type_counts
  end

  # === Memoization ===

  test "total is memoized" do
    first = @metrics.total
    # Modify underlying data
    @relation.first&.touch
    second = @metrics.total
    assert_equal first, second
  end
end
