require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @transaction = transactions(:amazon_purchase)
  end

  # === Authentication ===

  test "index requires authentication" do
    get transactions_url
    assert_redirected_to new_session_url
  end

  test "show requires authentication" do
    get transaction_url(@transaction)
    assert_redirected_to new_session_url
  end

  test "update requires authentication" do
    patch transaction_url(@transaction), params: { transaction: { category: "groceries" } }
    assert_redirected_to new_session_url
  end

  # === Index Action ===

  test "index returns success when authenticated" do
    sign_in_as(@user)
    get transactions_url
    assert_response :success
  end

  test "index only shows current user's transactions" do
    sign_in_as(@user)
    get transactions_url
    assert_response :success

    # Should show user one's transaction
    assert_match @transaction.merchant, response.body

    # Should not show user two's transaction
    other_transaction = transactions(:uber_ride)
    assert_no_match other_transaction.merchant, response.body
  end

  test "index filters by transaction_type parameter" do
    sign_in_as(@user)

    # Filter to expenses only
    get transactions_url(transaction_type: "expense")
    assert_response :success
    # Should show expense transactions
    assert_match @transaction.merchant, response.body
  end

  test "index filters to investment transactions" do
    sign_in_as(@user)
    get transactions_url(transaction_type: "investment")
    assert_response :success
    # Should show investment transactions
    investment = transactions(:investment)
    assert_match investment.merchant, response.body
  end

  test "index filters by search query" do
    sign_in_as(@user)
    get transactions_url(q: "Amazon")
    assert_response :success
    assert_match "Amazon", response.body
  end

  test "index combines search and transaction_type filters" do
    sign_in_as(@user)
    get transactions_url(q: "Amazon", transaction_type: "expense")
    assert_response :success
  end

  test "index renders without layout for turbo frame requests" do
    sign_in_as(@user)
    get transactions_url, headers: { "Turbo-Frame" => "transactions_list" }
    assert_response :success
  end

  # === Show Action ===

  test "show displays transaction details" do
    sign_in_as(@user)
    get transaction_url(@transaction)
    assert_response :success
    assert_match @transaction.merchant, response.body
  end

  test "show returns 404 for other user's transaction" do
    sign_in_as(@other_user)
    get transaction_url(@transaction)
    assert_response :not_found
  end

  test "show returns 404 for non-existent transaction" do
    sign_in_as(@user)
    get transaction_url(id: 999999)
    assert_response :not_found
  end

  # === Update Action ===

  test "update changes transaction category" do
    sign_in_as(@user)

    patch transaction_url(@transaction), params: {
      transaction: { category: "dining_out" }
    }

    assert_redirected_to transactions_url
    assert_equal "dining_out", @transaction.reload.category
  end

  test "update changes transaction_type" do
    sign_in_as(@user)

    patch transaction_url(@transaction), params: {
      transaction: { transaction_type: "investment" }
    }

    assert_redirected_to transactions_url
    assert @transaction.reload.investment?
  end

  test "update responds to turbo_stream" do
    sign_in_as(@user)

    patch transaction_url(@transaction), params: {
      transaction: { category: "groceries" }
    }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "update cannot modify other user's transaction" do
    sign_in_as(@other_user)
    original_category = @transaction.category

    patch transaction_url(@transaction), params: {
      transaction: { category: "hacked" }
    }

    assert_response :not_found
    # Original category should be unchanged
    assert_equal original_category, @transaction.reload.category
  end

  test "update only permits category and transaction_type params" do
    sign_in_as(@user)
    original_amount = @transaction.amount_cents
    original_merchant = @transaction.merchant

    patch transaction_url(@transaction), params: {
      transaction: {
        category: "groceries",
        amount_cents: 999999,
        merchant: "Hacked Merchant",
        notes: "Hacked Notes"
      }
    }

    @transaction.reload
    assert_equal "groceries", @transaction.category
    assert_equal original_amount, @transaction.amount_cents
    assert_equal original_merchant, @transaction.merchant
  end

  # === Authorization ===

  test "user cannot access transactions from another user in index" do
    sign_in_as(@other_user)
    get transactions_url
    assert_response :success

    # User two should not see user one's transactions
    assert_no_match @transaction.merchant, response.body

    # User two should see their own transactions
    uber_ride = transactions(:uber_ride)
    assert_match uber_ride.merchant, response.body
  end
end
