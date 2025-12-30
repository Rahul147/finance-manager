require "test_helper"

class EmailMetricsTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @relation = Email.for_user(@user.id)
    @metrics = EmailMetrics.new(@relation)
  end

  # === Basic Counts ===

  test "total counts all emails in relation" do
    expected = @relation.count
    assert_equal expected, @metrics.total
  end

  test "processed counts only processed emails" do
    expected = @relation.processed.count
    assert_equal expected, @metrics.processed
  end

  test "pending is difference between total and processed" do
    expected = @metrics.total - @metrics.processed
    assert_equal expected, @metrics.pending
  end

  # === Percentage Calculations ===

  test "processed_percentage calculates correctly" do
    if @metrics.total > 0
      expected = ((@metrics.processed.to_f / @metrics.total) * 100).round
      assert_equal expected, @metrics.processed_percentage
    else
      assert_equal 0, @metrics.processed_percentage
    end
  end

  test "processed_percentage returns zero when total is zero" do
    empty_metrics = EmailMetrics.new(Email.none)
    assert_equal 0, empty_metrics.processed_percentage
  end

  test "linked_percentage calculates correctly" do
    if @metrics.total > 0
      expected = ((@metrics.linked_transactions.to_f / @metrics.total) * 100).round
      assert_equal expected, @metrics.linked_percentage
    else
      assert_equal 0, @metrics.linked_percentage
    end
  end

  # === Transaction Linkage ===

  test "linked_transactions counts emails with transactions" do
    expected = @relation.joins(:financial_transaction).count
    assert_equal expected, @metrics.linked_transactions
  end

  # === Sender Analysis ===

  test "unique_senders counts distinct from addresses" do
    expected = @relation
      .where.not(from_address: [ nil, "" ])
      .distinct
      .count(:from_address)
    assert_equal expected, @metrics.unique_senders
  end

  test "top_senders returns most frequent senders" do
    senders = @metrics.top_senders
    assert senders.is_a?(Array)

    senders.each do |address, count|
      assert address.is_a?(String)
      assert count.is_a?(Integer)
      assert count > 0
    end
  end

  test "top_senders sorted by count descending" do
    senders = @metrics.top_senders
    return if senders.size < 2

    senders.each_cons(2) do |higher, lower|
      assert higher[1] >= lower[1], "Expected #{higher[1]} >= #{lower[1]}"
    end
  end

  test "top_senders respects limit parameter" do
    senders = @metrics.top_senders(2)
    assert senders.size <= 2
  end

  test "top_senders uses default limit of 4" do
    # Ensure we have enough senders
    senders = @metrics.top_senders
    assert senders.size <= 4
  end

  # === Activity Tracking ===

  test "latest_activity_at returns most recent created_at" do
    expected = @relation.maximum(:created_at)
    assert_equal expected, @metrics.latest_activity_at
  end

  test "latest_activity_at returns nil for empty relation" do
    empty_metrics = EmailMetrics.new(Email.none)
    assert_nil empty_metrics.latest_activity_at
  end

  # === Filtered Relations ===

  test "works with filtered relation" do
    filtered = @relation.processed
    metrics = EmailMetrics.new(filtered)

    assert metrics.total <= @metrics.total
    assert_equal metrics.total, metrics.processed # All should be processed
  end

  test "works with search filtered relation" do
    searched = @relation.search("Axis")
    metrics = EmailMetrics.new(searched)

    assert metrics.total > 0
    assert_respond_to metrics, :unique_senders
    assert_respond_to metrics, :top_senders
  end

  # === Edge Cases ===

  test "handles empty relation" do
    empty_metrics = EmailMetrics.new(Email.none)

    assert_equal 0, empty_metrics.total
    assert_equal 0, empty_metrics.processed
    assert_equal 0, empty_metrics.pending
    assert_equal 0, empty_metrics.processed_percentage
    assert_equal 0, empty_metrics.linked_transactions
    assert_equal 0, empty_metrics.linked_percentage
    assert_equal 0, empty_metrics.unique_senders
    assert_equal [], empty_metrics.top_senders
    assert_nil empty_metrics.latest_activity_at
  end

  test "handles emails without from_address" do
    # Create email without from_address
    email = emails(:axis_debit)
    email.update_column(:from_address, nil)

    metrics = EmailMetrics.new(Email.where(id: email.id))
    assert_equal 0, metrics.unique_senders
    assert_equal [], metrics.top_senders
  end

  # === Memoization ===

  test "total is memoized" do
    first = @metrics.total
    second = @metrics.total
    assert_equal first, second
  end

  test "top_senders is memoized" do
    first = @metrics.top_senders
    second = @metrics.top_senders
    assert_equal first.object_id, second.object_id
  end

  # === Real World Scenarios ===

  test "reflects actual email processing status" do
    processed_count = @relation.where(processed: true).count
    unprocessed_count = @relation.where(processed: false).count

    assert_equal processed_count, @metrics.processed
    assert_equal unprocessed_count, @metrics.pending
  end
end
