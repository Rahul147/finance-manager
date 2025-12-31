require "application_system_test_case"

class EmailsTest < ApplicationSystemTestCase
  test "viewing emails index" do
    user = User.create!(email_address: "email_test@example.com", password: "password", email_verified_at: Time.current)
    account = EmailAccount.create!(
      user: user,
      email_address: user.email_address,
      provider: "google",
      provider_account_id: "email_test_id"
    )
    Email.create!(
      user: user,
      email_account: account,
      message_id: "email_test_msg",
      subject: "Test Email Subject",
      from_address: "sender@bank.com"
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"
    assert_text "Dashboard"

    visit emails_path
    assert_text "Test Email Subject"
  end

  test "viewing a single email" do
    user = User.create!(email_address: "email_show_test@example.com", password: "password", email_verified_at: Time.current)
    account = EmailAccount.create!(
      user: user,
      email_address: user.email_address,
      provider: "google",
      provider_account_id: "email_show_test_id"
    )
    email = Email.create!(
      user: user,
      email_account: account,
      message_id: "email_show_test_msg",
      subject: "Show Email Subject",
      from_address: "sender@bank.com"
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"
    assert_text "Dashboard"

    visit emails_path
    assert_text "Show Email Subject"
  end
end
