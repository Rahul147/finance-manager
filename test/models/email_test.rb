require "test_helper"

class EmailTest < ActiveSupport::TestCase
  # === Associations ===

  test "belongs to user" do
    email = emails(:axis_debit)
    assert_equal users(:one), email.user
  end

  test "belongs to email_account" do
    email = emails(:axis_debit)
    assert_equal email_accounts(:one), email.email_account
  end

  test "has one financial_transaction" do
    email = emails(:axis_debit)
    assert email.financial_transaction.present?
    assert_instance_of Transaction, email.financial_transaction
  end

  test "destroying email destroys associated transaction" do
    # Create a fresh email and transaction without fixture dependencies
    user = users(:one)
    account = email_accounts(:one)

    email = Email.create!(
      user: user,
      email_account: account,
      message_id: "test_destroy_#{SecureRandom.hex(8)}",
      thread_id: "thread_test",
      subject: "Test Email for Destruction",
      from_address: "test@example.com",
      sent_at: Time.current
    )

    transaction = Transaction.create!(
      email: email,
      user: user,
      merchant: "Test Merchant",
      amount_cents: 1000,
      currency: "INR",
      transaction_type: :expense
    )

    transaction_id = transaction.id

    assert_difference "Transaction.count", -1 do
      email.destroy
    end

    assert_nil Transaction.find_by(id: transaction_id)
  end

  # === Scopes ===

  test "for_user scope returns only emails for specified user" do
    user_one_emails = Email.for_user(users(:one).id)
    user_one_emails.each do |email|
      assert_equal users(:one).id, email.user_id
    end

    # Ensure we're not getting user two's emails
    user_two_ids = Email.for_user(users(:two).id).pluck(:id)
    assert_not user_one_emails.pluck(:id).intersect?(user_two_ids)
  end

  test "processed scope returns only processed emails" do
    processed_emails = Email.processed
    processed_emails.each do |email|
      assert email.processed?, "Email #{email.id} should be processed"
    end
  end

  test "ordered_newest orders by sent_at descending" do
    emails = Email.for_user(users(:one).id).ordered_newest.to_a
    return if emails.size < 2

    emails.each_cons(2) do |newer, older|
      if newer.sent_at && older.sent_at
        assert newer.sent_at >= older.sent_at,
          "Expected #{newer.sent_at} >= #{older.sent_at}"
      end
    end
  end

  # === Search Scope ===

  test "search finds emails by subject" do
    results = Email.search("Axis Bank")
    assert results.any?
    assert results.all? { |e| e.subject.downcase.include?("axis bank") || e.from_address.downcase.include?("axis") }
  end

  test "search finds emails by from_address" do
    results = Email.search("axisbank.com")
    assert results.any?
    assert results.all? { |e| e.from_address.downcase.include?("axisbank.com") }
  end

  test "search finds emails by snippet" do
    results = Email.search("Amazon")
    assert results.any?
    assert results.any? { |e| e.snippet.downcase.include?("amazon") }
  end

  test "search returns all emails when query is blank" do
    assert_equal Email.count, Email.search("").count
    assert_equal Email.count, Email.search(nil).count
    assert_equal Email.count, Email.search("   ").count
  end

  test "search is case insensitive" do
    results_lower = Email.search("axis")
    results_upper = Email.search("AXIS")

    assert_equal results_lower.count, results_upper.count
    assert results_lower.any?
  end

  test "search handles special SQL characters safely" do
    # These should not cause SQL errors
    results = Email.search("100%")
    assert results.is_a?(ActiveRecord::Relation)

    results = Email.search("test_underscore")
    assert results.is_a?(ActiveRecord::Relation)

    results = Email.search("'; DROP TABLE emails; --")
    assert results.is_a?(ActiveRecord::Relation)
  end

  # === Email Data ===

  test "stores email headers as JSON" do
    email = emails(:axis_debit)
    headers = JSON.parse(email.headers)
    assert headers.is_a?(Hash)
    assert headers.key?("From")
  end

  test "email can have both text and html body" do
    email = emails(:axis_debit)
    assert email.body_text.present?
    assert email.body_html.present?
  end

  test "processed flag distinguishes processed and unprocessed emails" do
    processed_email = emails(:axis_debit)
    unprocessed_email = emails(:icici_upi)

    assert processed_email.processed?
    assert_not unprocessed_email.processed?
  end
end
