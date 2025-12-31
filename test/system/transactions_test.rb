require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  test "viewing transactions index" do
    user = User.create!(email_address: "trans_test@example.com", password: "password", email_verified_at: Time.current)
    account = EmailAccount.create!(
      user: user,
      email_address: user.email_address,
      provider: "google",
      provider_account_id: "trans_test_id"
    )
    email = Email.create!(
      user: user,
      email_account: account,
      message_id: "trans_test_msg",
      subject: "Test Transaction Email"
    )
    Transaction.create!(
      user: user,
      email: email,
      merchant: "Test Merchant",
      amount_cents: 10000,
      currency: "INR",
      transaction_type: :expense
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    click_link "Transactions"
    assert_text "Test Merchant"
    assert_text "LEDGER"
  end

  test "viewing a single transaction" do
    user = User.create!(email_address: "trans_show_test@example.com", password: "password", email_verified_at: Time.current)
    account = EmailAccount.create!(
      user: user,
      email_address: user.email_address,
      provider: "google",
      provider_account_id: "trans_show_test_id"
    )
    email = Email.create!(
      user: user,
      email_account: account,
      message_id: "trans_show_test_msg",
      subject: "Show Transaction Email"
    )
    transaction = Transaction.create!(
      user: user,
      email: email,
      merchant: "Show Test Merchant",
      amount_cents: 15000,
      currency: "INR",
      transaction_type: :expense
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    click_link "Transactions"
    assert_text "Show Test Merchant"
  end
end
