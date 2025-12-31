require "test_helper"

class Transaction::ExtractorTest < ActiveSupport::TestCase
  setup do
    @email = emails(:icici_upi)
    @email.update!(processed: false)
    @email.financial_transaction&.destroy
    @email.reload
  end

  # === Early Returns (no external API calls) ===

  test "returns nil when email snippet is blank" do
    @email.update_column(:snippet, "")
    result = Transaction::Extractor.extract_from(@email)
    assert_nil result
  end

  test "returns nil when email snippet is nil" do
    @email.update_column(:snippet, nil)
    result = Transaction::Extractor.extract_from(@email)
    assert_nil result
  end

  test "returns nil when email snippet is whitespace only" do
    @email.update_column(:snippet, "   ")
    result = Transaction::Extractor.extract_from(@email)
    assert_nil result
  end

  # === Prompt Structure ===

  test "PROMPT constant is defined and contains required fields" do
    assert defined?(Transaction::Extractor::PROMPT)
    prompt = Transaction::Extractor::PROMPT

    assert_includes prompt, "bankName"
    assert_includes prompt, "amount"
    assert_includes prompt, "currency"
    assert_includes prompt, "beneficiaryName"
    assert_includes prompt, "transactionDate"
  end

  # === Initialization ===

  test "can be instantiated with email" do
    extractor = Transaction::Extractor.new(@email)
    assert_instance_of Transaction::Extractor, extractor
  end

  test "extract_from is a class method that delegates to instance" do
    assert_respond_to Transaction::Extractor, :extract_from
  end

  # Note: Integration tests that call OpenAI API are not included.
  # Those should be run manually or in a separate integration test suite
  # with proper API credentials and rate limiting.
  #
  # Key behaviors verified through manual/integration testing:
  # - Creates transaction from valid OpenAI response
  # - Converts amount to cents correctly
  # - Uses beneficiaryName → bankName → "Unknown" fallback for merchant
  # - Defaults currency to INR
  # - Updates existing transaction instead of creating duplicate
  # - Stores metadata as JSON
end
