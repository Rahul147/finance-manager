require "test_helper"

class UserTest < ActiveSupport::TestCase
  # === Email Normalization ===

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "normalizes email on assignment" do
    user = users(:one)
    user.email_address = "  NEW@EXAMPLE.COM  "
    assert_equal "new@example.com", user.email_address
  end

  # === Password Validation (has_secure_password) ===

  test "requires password for new users" do
    user = User.new(email_address: "new@example.com")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "accepts valid password" do
    user = User.new(email_address: "new@example.com", password: "securepassword123")
    assert user.valid?
  end

  test "authenticates with correct password" do
    user = users(:one)
    assert user.authenticate("password")
  end

  test "rejects incorrect password" do
    user = users(:one)
    assert_not user.authenticate("wrongpassword")
  end

  test "authenticate returns user on success" do
    user = users(:one)
    result = user.authenticate("password")
    assert_equal user, result
  end

  test "authenticate returns false on failure" do
    user = users(:one)
    result = user.authenticate("wrongpassword")
    assert_equal false, result
  end

  # === Associations ===

  test "has many sessions" do
    user = users(:one)
    assert_respond_to user, :sessions
    session = user.sessions.create!
    assert_includes user.sessions, session
  end

  test "has many email_accounts" do
    user = users(:one)
    assert_respond_to user, :email_accounts
    assert user.email_accounts.any?
  end

  test "has many emails" do
    user = users(:one)
    assert_respond_to user, :emails
    assert user.emails.any?
  end

  test "has many transactions" do
    user = users(:one)
    assert_respond_to user, :transactions
    assert user.transactions.any?
  end

  # === Dependent Destroy ===

  test "destroys sessions when user is destroyed" do
    user = User.create!(email_address: "destroy@example.com", password: "password")
    session = user.sessions.create!
    session_id = session.id

    user.destroy!

    assert_nil Session.find_by(id: session_id)
  end

  test "destroys email_accounts when user is destroyed" do
    user = User.create!(email_address: "destroy@example.com", password: "password")
    account = user.email_accounts.create!(
      provider: "google",
      provider_account_id: "test_acct",
      email_address: "linked@gmail.com"
    )
    account_id = account.id

    user.destroy!

    assert_nil EmailAccount.find_by(id: account_id)
  end

  test "emails association has dependent destroy" do
    # Verify the association is configured correctly
    association = User.reflect_on_association(:emails)
    assert_equal :destroy, association.options[:dependent]
  end

  test "transactions association has dependent destroy" do
    # Verify the association is configured correctly
    association = User.reflect_on_association(:transactions)
    assert_equal :destroy, association.options[:dependent]
  end

  # === Class Methods ===

  test "authenticate_by finds user with correct credentials" do
    result = User.authenticate_by(email_address: "one@example.com", password: "password")
    assert_equal users(:one), result
  end

  test "authenticate_by returns nil with wrong password" do
    result = User.authenticate_by(email_address: "one@example.com", password: "wrong")
    assert_nil result
  end

  test "authenticate_by returns nil for non-existent user" do
    result = User.authenticate_by(email_address: "nonexistent@example.com", password: "password")
    assert_nil result
  end

  test "authenticate_by is case insensitive for email" do
    result = User.authenticate_by(email_address: "ONE@EXAMPLE.COM", password: "password")
    assert_equal users(:one), result
  end

  # === Edge Cases ===

  test "can update password" do
    user = users(:one)
    user.update!(password: "newpassword123")

    assert user.authenticate("newpassword123")
    assert_not user.authenticate("password")
  end

  test "password_digest is set automatically" do
    user = User.new(email_address: "digest@example.com", password: "testpassword")
    user.save!

    assert_not_nil user.password_digest
    assert_not_equal "testpassword", user.password_digest
  end
end
