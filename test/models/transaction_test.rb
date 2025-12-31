require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # === Associations ===

  test "belongs to user" do
    transaction = transactions(:amazon_purchase)
    assert_equal users(:one), transaction.user
  end

  test "belongs to email" do
    transaction = transactions(:amazon_purchase)
    assert_equal emails(:axis_debit), transaction.email
  end

  # === Validations ===

  test "requires transaction_type" do
    transaction = Transaction.new(
      user: users(:one),
      email: emails(:axis_debit),
      transaction_type: nil
    )
    # Allow saving bypassing validation to test the actual validation message
    transaction.transaction_type = nil
    assert_not transaction.valid?
    assert_includes transaction.errors[:transaction_type], "can't be blank"
  end

  test "validates transaction_type inclusion" do
    transaction = transactions(:amazon_purchase)
    assert transaction.valid?

    # Valid types should work
    %w[expense investment transfer loan].each do |type|
      transaction.transaction_type = type
      assert transaction.valid?, "Should be valid with transaction_type: #{type}"
    end
  end

  # === Default Values ===

  test "defaults transaction_type to expense for new records" do
    transaction = Transaction.new
    assert_equal "expense", transaction.transaction_type
  end

  test "does not override existing transaction_type" do
    transaction = Transaction.new(transaction_type: :investment)
    assert_equal "investment", transaction.transaction_type
  end

  # === Enum ===

  test "expense transaction type enum" do
    transaction = transactions(:amazon_purchase)
    assert transaction.expense?
    assert_not transaction.investment?
  end

  test "investment transaction type enum" do
    transaction = transactions(:investment)
    assert transaction.investment?
    assert_not transaction.expense?
  end

  test "loan transaction type enum" do
    transaction = transactions(:loan_emi)
    assert transaction.loan?
  end

  test "transfer transaction type enum" do
    transaction = transactions(:transfer)
    assert transaction.transfer?
  end

  # === Scopes ===

  test "expenses scope returns only expense transactions" do
    expenses = Transaction.expenses
    expenses.each do |t|
      assert t.expense?, "Transaction #{t.id} should be an expense"
    end
  end

  test "for_user scope returns only transactions for specified user" do
    user_one_transactions = Transaction.for_user(users(:one).id)
    user_one_transactions.each do |t|
      assert_equal users(:one).id, t.user_id
    end

    user_two_transactions = Transaction.for_user(users(:two).id)
    user_two_transactions.each do |t|
      assert_equal users(:two).id, t.user_id
    end

    # Verify different counts
    assert user_one_transactions.count > user_two_transactions.count
  end

  test "ordered_newest scope orders by transaction_date descending" do
    transactions = Transaction.for_user(users(:one).id).ordered_newest.to_a
    return if transactions.size < 2

    transactions.each_cons(2) do |newer, older|
      # Allow equal dates (secondary sort by created_at)
      if newer.transaction_date && older.transaction_date
        assert newer.transaction_date >= older.transaction_date,
          "Expected #{newer.transaction_date} >= #{older.transaction_date}"
      end
    end
  end

  test "search scope finds transactions by merchant" do
    results = Transaction.search("Amazon")
    assert results.any?
    assert results.all? { |t| t.merchant.downcase.include?("amazon") }
  end

  test "search scope finds transactions by category key" do
    results = Transaction.search("groceries")
    assert results.any?
    assert results.all? { |t| t.category == "groceries" || t.category.to_s.downcase.include?("groceries") }
  end

  test "search scope finds transactions by category label" do
    results = Transaction.search("Food Delivery")
    assert results.any?
    assert results.any? { |t| t.category == "food_delivery" }
  end

  test "search scope finds transactions by notes" do
    results = Transaction.search("Home loan EMI")
    assert results.any?
    assert results.any? { |t| t.notes.downcase.include?("home loan emi") }
  end

  test "search scope returns all when query is blank" do
    assert_equal Transaction.count, Transaction.search("").count
    assert_equal Transaction.count, Transaction.search(nil).count
    assert_equal Transaction.count, Transaction.search("   ").count
  end

  test "search scope is case insensitive" do
    results_lower = Transaction.search("amazon")
    results_upper = Transaction.search("AMAZON")
    results_mixed = Transaction.search("AmAzOn")

    assert_equal results_lower.count, results_upper.count
    assert_equal results_lower.count, results_mixed.count
  end

  # === Category Methods ===

  test "category_options returns frozen hash of categories" do
    options = Transaction.category_options
    assert options.frozen?
    assert_includes options.keys, :groceries
    assert_equal "Groceries", options[:groceries]
  end

  test "category_options_for_select returns array suitable for select helper" do
    options = Transaction.category_options_for_select
    assert options.is_a?(Array)
    assert options.all? { |item| item.is_a?(Array) && item.size == 2 }

    groceries_option = options.find { |label, _key| label == "Groceries" }
    assert groceries_option
    assert_equal "groceries", groceries_option[1]
  end

  test "category_key_for returns key when given valid key" do
    assert_equal "groceries", Transaction.category_key_for("groceries")
    assert_equal "food_delivery", Transaction.category_key_for("food_delivery")
  end

  test "category_key_for returns key when given label" do
    assert_equal "groceries", Transaction.category_key_for("Groceries")
    assert_equal "food_delivery", Transaction.category_key_for("Food Delivery")
  end

  test "category_key_for returns nil for blank values" do
    assert_nil Transaction.category_key_for("")
    assert_nil Transaction.category_key_for(nil)
  end

  test "category_label_for returns label when given key" do
    assert_equal "Groceries", Transaction.category_label_for("groceries")
    assert_equal "Food Delivery", Transaction.category_label_for("food_delivery")
  end

  test "category_label_for returns label when given symbol key" do
    assert_equal "Groceries", Transaction.category_label_for(:groceries)
  end

  test "category_label_for returns value as string for unknown categories" do
    assert_equal "some_unknown", Transaction.category_label_for("some_unknown")
  end

  test "category_label_for returns nil for blank values" do
    assert_nil Transaction.category_label_for("")
    assert_nil Transaction.category_label_for(nil)
  end

  # === Transaction Type Methods ===

  test "transaction_type_options_for_select returns array suitable for select helper" do
    options = Transaction.transaction_type_options_for_select
    assert options.is_a?(Array)

    labels = options.map(&:first)
    assert_includes labels, "Expense"
    assert_includes labels, "Investment"
    assert_includes labels, "Transfer"
    assert_includes labels, "Loan"
  end

  test "transaction_type_label returns human readable label" do
    assert_equal "Expense", transactions(:amazon_purchase).transaction_type_label
    assert_equal "Investment", transactions(:investment).transaction_type_label
    assert_equal "Loan", transactions(:loan_emi).transaction_type_label
    assert_equal "Transfer", transactions(:transfer).transaction_type_label
  end

  # === Instance Methods ===

  test "category_display returns human readable category" do
    transaction = transactions(:amazon_purchase)
    transaction.category = "groceries"
    assert_equal "Groceries", transaction.category_display
  end

  test "category_display returns Uncategorized when category is blank" do
    transaction = transactions(:amazon_purchase)
    transaction.category = ""
    assert_equal "Uncategorized", transaction.category_display

    transaction.category = nil
    assert_equal "Uncategorized", transaction.category_display
  end

  test "category_select_value returns key for select dropdown" do
    transaction = transactions(:amazon_purchase)
    transaction.category = "groceries"
    assert_equal "groceries", transaction.category_select_value
  end

  test "transaction_type_select_value returns key string" do
    assert_equal "expense", transactions(:amazon_purchase).transaction_type_select_value
    assert_equal "investment", transactions(:investment).transaction_type_select_value
  end

  # === Status Label ===

  test "status_label returns status when present" do
    transaction = transactions(:amazon_purchase)
    transaction.status = "parsed"
    assert_equal "parsed", transaction.status_label
  end

  test "status_label returns Unlabeled when status is nil" do
    transaction = transactions(:amazon_purchase)
    transaction.status = nil
    assert_equal "Unlabeled", transaction.status_label
  end

  test "status_label returns Unlabeled when status is blank" do
    transaction = transactions(:amazon_purchase)
    transaction.status = ""
    assert_equal "Unlabeled", transaction.status_label
  end

  # === Class Methods for Type Normalization ===

  test "normalize_type_key returns string key when given string" do
    assert_equal "expense", Transaction.normalize_type_key("expense")
    assert_equal "investment", Transaction.normalize_type_key("investment")
  end

  test "normalize_type_key converts integer to string key" do
    assert_equal "expense", Transaction.normalize_type_key(0)
    assert_equal "investment", Transaction.normalize_type_key(1)
    assert_equal "transfer", Transaction.normalize_type_key(2)
    assert_equal "loan", Transaction.normalize_type_key(3)
  end

  test "type_label_for returns human readable label" do
    assert_equal "Expense", Transaction.type_label_for("expense")
    assert_equal "Investment", Transaction.type_label_for("investment")
    assert_equal "Transfer", Transaction.type_label_for("transfer")
    assert_equal "Loan", Transaction.type_label_for("loan")
  end

  test "type_label_for returns Unknown for nil" do
    assert_equal "Unknown", Transaction.type_label_for(nil)
  end

  test "type_label_for returns Unknown for blank string" do
    assert_equal "Unknown", Transaction.type_label_for("")
  end

  test "type_label_for humanizes unknown types" do
    assert_equal "Some new type", Transaction.type_label_for("some_new_type")
  end

  # === Search Edge Cases ===

  test "search handles special SQL characters safely" do
    # These should not cause SQL errors
    assert_nothing_raised do
      Transaction.search("%")
      Transaction.search("_")
      Transaction.search("'")
      Transaction.search("\\")
      Transaction.search("%;DROP TABLE transactions;--")
    end
  end

  test "search with very long query does not error" do
    long_query = "a" * 1000
    assert_nothing_raised do
      Transaction.search(long_query)
    end
  end

  test "search with unicode characters works" do
    results = Transaction.search("₹")
    assert_kind_of ActiveRecord::Relation, results
  end

  test "search matches partial merchant names" do
    results = Transaction.search("Amaz")
    assert results.any? { |t| t.merchant.include?("Amazon") }
  end

  # === Amounts and Currency ===

  test "amount_cents can store large values" do
    transaction = transactions(:amazon_purchase)
    transaction.amount_cents = 999_999_999_99 # ~10 billion cents
    transaction.save!
    transaction.reload
    assert_equal 999_999_999_99, transaction.amount_cents
  end

  test "currency is stored as string" do
    transaction = transactions(:amazon_purchase)
    assert_equal "INR", transaction.currency
  end
end
