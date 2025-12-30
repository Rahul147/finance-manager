require "test_helper"

class EmailAccountTest < ActiveSupport::TestCase
  # === Associations ===

  test "belongs to user" do
    account = email_accounts(:one)
    assert_equal users(:one), account.user
  end

  # === Validations ===

  test "requires email_address" do
    account = EmailAccount.new(
      user: users(:one),
      provider: "google",
      provider_account_id: "unique_id_123"
    )
    assert_not account.valid?
    assert_includes account.errors[:email_address], "can't be blank"
  end

  test "requires provider" do
    account = EmailAccount.new(
      user: users(:one),
      email_address: "test@gmail.com",
      provider_account_id: "unique_id_123"
    )
    assert_not account.valid?
    assert_includes account.errors[:provider], "can't be blank"
  end

  test "requires provider_account_id" do
    account = EmailAccount.new(
      user: users(:one),
      email_address: "test@gmail.com",
      provider: "google"
    )
    assert_not account.valid?
    assert_includes account.errors[:provider_account_id], "can't be blank"
  end

  test "provider_account_id must be unique per provider" do
    existing = email_accounts(:one)
    duplicate = EmailAccount.new(
      user: users(:two),
      email_address: "different@gmail.com",
      provider: existing.provider,
      provider_account_id: existing.provider_account_id
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider_account_id], "has already been taken"
  end

  test "same provider_account_id can exist for different providers" do
    existing = email_accounts(:one)
    different_provider = EmailAccount.new(
      user: users(:two),
      email_address: "test@outlook.com",
      provider: "microsoft",
      provider_account_id: existing.provider_account_id
    )

    assert different_provider.valid?
  end

  test "valid email account saves successfully" do
    account = EmailAccount.new(
      user: users(:one),
      email_address: "newaccount@gmail.com",
      provider: "google",
      provider_account_id: "brand_new_unique_id",
      access_token: "test_token",
      refresh_token: "test_refresh",
      expires_at: 1.hour.from_now,
      status: "active"
    )

    assert account.save
    assert account.persisted?
  end

  # === Token Encryption ===

  test "encrypts access_token when saving" do
    account = EmailAccount.create!(
      user: users(:one),
      email_address: "encrypt_test@gmail.com",
      provider: "google",
      provider_account_id: "encrypt_test_id",
      access_token: "my_secret_access_token",
      refresh_token: "my_secret_refresh_token"
    )

    # Token should be readable after save
    assert_equal "my_secret_access_token", account.access_token
    assert_equal "my_secret_refresh_token", account.refresh_token

    # Reload from database - should still be decryptable
    account.reload
    assert_equal "my_secret_access_token", account.access_token
    assert_equal "my_secret_refresh_token", account.refresh_token
  end

  test "tokens can be nil" do
    account = email_accounts(:inactive)
    assert_nil account.access_token
    assert_nil account.refresh_token
  end

  # === Token Expiration ===

  test "expired? returns false when expires_at is in the future" do
    account = email_accounts(:one)
    account.expires_at = 1.hour.from_now
    assert_not account.expired?
  end

  test "expired? returns true when expires_at is in the past" do
    account = email_accounts(:expired)
    assert account.expired?
  end

  test "expired? returns false when expires_at is nil" do
    account = email_accounts(:one)
    account.expires_at = nil
    assert_not account.expired?
  end

  test "expired? returns true when expires_at equals current time" do
    account = email_accounts(:one)
    freeze_time do
      account.expires_at = Time.current
      assert account.expired?
    end
  end

  # === Status ===

  test "can track active status" do
    account = email_accounts(:one)
    assert_equal "active", account.status
  end

  test "can track inactive status" do
    account = email_accounts(:inactive)
    assert_equal "inactive", account.status
  end

  test "status can be updated" do
    account = email_accounts(:one)
    account.update!(status: "inactive")
    assert_equal "inactive", account.reload.status
  end

  # === OAuth Scope ===

  test "stores OAuth scope" do
    account = email_accounts(:one)
    assert account.scope.present?
    assert_includes account.scope, "gmail"
  end
end
