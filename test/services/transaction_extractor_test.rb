require "test_helper"

class TransactionExtractorTest < ActiveSupport::TestCase
  setup do
    @email = emails(:icici_upi)
    @email.update!(processed: false)
  end

  # === Early Returns (no external API calls needed) ===

  test "returns nil when email snippet is blank" do
    @email.update_column(:snippet, "")
    result = TransactionExtractor.extract!(@email)
    assert_nil result
  end

  test "returns nil when email snippet is nil" do
    @email.update_column(:snippet, nil)
    result = TransactionExtractor.extract!(@email)
    assert_nil result
  end

  test "returns nil when email snippet is whitespace only" do
    @email.update_column(:snippet, "   ")
    result = TransactionExtractor.extract!(@email)
    assert_nil result
  end

  # Note: Tests that actually call OpenAI API are not included in the standard test suite.
  # Integration tests with real API calls should be done in a separate suite with proper
  # API credentials and rate limiting considerations.
  #
  # The TransactionExtractor's behavior is primarily tested through:
  # 1. Early return tests above (no API call)
  # 2. Manual testing with real emails
  # 3. Optional integration test suite with OpenAI sandbox
  #
  # Key behaviors that would be tested in integration:
  # - Creates transaction from valid OpenAI response
  # - Returns nil when JSON parsing fails
  # - Returns nil when amount is zero or negative
  # - Converts amount to cents correctly
  # - Uses beneficiaryName/bankName/Unknown as merchant fallback
  # - Defaults currency to INR
  # - Updates existing transaction instead of creating duplicate
  # - Associates transaction with email and user
end
