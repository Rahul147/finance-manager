require "test_helper"
require "ostruct"

class GoogleGmailTest < ActiveSupport::TestCase
  setup do
    @account = email_accounts(:one)
    # Ensure GoogleGmail is loaded (also loads GoogleReauthNeeded defined in same file)
    GoogleGmail
  end

  # === Helper Methods (no external API calls) ===

  test "headers_hash converts headers array to hash" do
    headers = [
      OpenStruct.new(name: "From", value: "test@example.com"),
      OpenStruct.new(name: "Subject", value: "Test Subject"),
      OpenStruct.new(name: "Date", value: "Mon, 15 Dec 2024 10:00:00 +0530")
    ]

    result = GoogleGmail.headers_hash(headers)

    assert_equal "test@example.com", result["From"]
    assert_equal "Test Subject", result["Subject"]
    assert_equal "Mon, 15 Dec 2024 10:00:00 +0530", result["Date"]
  end

  test "headers_hash handles nil headers" do
    result = GoogleGmail.headers_hash(nil)
    assert_equal({}, result)
  end

  test "headers_hash handles empty headers" do
    result = GoogleGmail.headers_hash([])
    assert_equal({}, result)
  end

  # === Subject Blacklisting ===

  test "blacklisted_subject returns true for Login emails" do
    assert GoogleGmail.blacklisted_subject?("Login Alert from Your Bank")
    assert GoogleGmail.blacklisted_subject?("LOGIN notification")
    assert GoogleGmail.blacklisted_subject?("Your login was successful")
  end

  test "blacklisted_subject returns true for Payment Received emails" do
    assert GoogleGmail.blacklisted_subject?("Payment Received confirmation")
    assert GoogleGmail.blacklisted_subject?("PAYMENT RECEIVED from customer")
  end

  test "blacklisted_subject returns false for transaction emails" do
    assert_not GoogleGmail.blacklisted_subject?("Transaction Alert from Axis Bank")
    assert_not GoogleGmail.blacklisted_subject?("Your card was used for INR 500")
    assert_not GoogleGmail.blacklisted_subject?("Debit Alert")
  end

  test "blacklisted_subject handles nil" do
    assert_not GoogleGmail.blacklisted_subject?(nil)
  end

  test "blacklisted_subject handles empty string" do
    assert_not GoogleGmail.blacklisted_subject?("")
  end

  # === Time Inference ===

  test "infer_sent_at parses Date header when present" do
    headers = { "Date" => "Mon, 15 Dec 2024 10:00:00 +0530" }
    result = GoogleGmail.infer_sent_at(headers, nil)

    assert_instance_of Time, result
    assert_equal 2024, result.year
    assert_equal 12, result.month
    assert_equal 15, result.day
  end

  test "infer_sent_at falls back to internal_date when Date header is missing" do
    headers = {}
    internal_ms = 1702627200000 # Dec 15, 2023 in milliseconds

    result = GoogleGmail.infer_sent_at(headers, internal_ms)

    assert_instance_of Time, result
  end

  test "infer_sent_at falls back to internal_date when Date header is invalid" do
    headers = { "Date" => "not a valid date" }
    internal_ms = 1702627200000

    result = GoogleGmail.infer_sent_at(headers, internal_ms)

    assert_instance_of Time, result
  end

  test "safe_internal_time converts milliseconds to Time" do
    internal_ms = 1702627200000 # Known timestamp

    result = GoogleGmail.safe_internal_time(internal_ms)

    assert_instance_of Time, result
  end

  test "safe_internal_time returns current time for nil" do
    freeze_time do
      result = GoogleGmail.safe_internal_time(nil)
      assert_equal Time.current.to_i, result.to_i
    end
  end

  # === HTML Text Extraction ===

  test "extract_hrml_text returns nil for empty parts" do
    text, html = GoogleGmail.extract_hrml_text([])

    assert_nil text
    assert_nil html
  end

  test "extract_hrml_text handles nil parts" do
    text, html = GoogleGmail.extract_hrml_text(nil)

    assert_nil text
    assert_nil html
  end

  test "extract_hrml_text extracts text from HTML" do
    parts = [
      OpenStruct.new(
        mime_type: "text/html",
        body: OpenStruct.new(data: "<html><body><p>Test Transaction INR 500</p></body></html>")
      )
    ]

    text, html = GoogleGmail.extract_hrml_text(parts)

    assert_not_nil text
    assert_not_nil html
    assert_match(/Test Transaction/, text)
  end

  # === Constants ===

  test "BLACKLIST_SUBJECTS contains expected values" do
    assert GoogleGmail::BLACKLIST_SUBJECTS.include?("login")
    assert GoogleGmail::BLACKLIST_SUBJECTS.include?("payment received")
  end

  test "SCOPES contains Gmail readonly scope" do
    assert GoogleGmail::SCOPES.include?(Google::Apis::GmailV1::AUTH_GMAIL_READONLY)
  end

  # === Error Class ===

  test "GoogleReauthNeeded is a StandardError" do
    error = GoogleReauthNeeded.new("Token expired")
    assert_instance_of GoogleReauthNeeded, error
    assert_kind_of StandardError, error
    assert_equal "Token expired", error.message
  end

  # === Token Expiration ===

  test "expired account is detected" do
    expired_account = email_accounts(:expired)
    assert expired_account.expired?
  end

  test "active account is not expired" do
    assert_not @account.expired?
  end

  # Note: Tests that require actual Gmail API calls are not included.
  # Integration tests with real OAuth credentials should be in a separate suite.
  #
  # Key behaviors to test in integration:
  # - service_for creates authenticated Gmail service
  # - Token refresh works when token is expired
  # - ingest_latest fetches and creates Email records
  # - ingest_latest enqueues ExtractTransactionFromEmailJob
  # - Duplicate emails are skipped (message_id check)
end
