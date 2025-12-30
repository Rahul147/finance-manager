require "application_system_test_case"

class DashboardAccountStatusTest < ApplicationSystemTestCase
  test "dashboard shows active account status" do
    user = User.create!(email_address: "status_test@example.com", password: "password")
    EmailAccount.create!(
      user: user,
      email_address: "active@gmail.com",
      provider: "google",
      provider_account_id: "active_test_id",
      status: "active"
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    assert_text "active@gmail.com"
    assert_text "ACTIVE"
  end

  test "dashboard shows inactive account status" do
    user = User.create!(email_address: "inactive_test@example.com", password: "password")
    EmailAccount.create!(
      user: user,
      email_address: "inactive@gmail.com",
      provider: "google",
      provider_account_id: "inactive_test_id",
      status: "inactive"
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    assert_text "inactive@gmail.com"
    assert_text "INACTIVE"
  end

  test "dashboard shows multiple accounts with different statuses" do
    user = User.create!(email_address: "multi_status@example.com", password: "password")
    EmailAccount.create!(
      user: user,
      email_address: "working@gmail.com",
      provider: "google",
      provider_account_id: "working_id",
      status: "active"
    )
    EmailAccount.create!(
      user: user,
      email_address: "broken@gmail.com",
      provider: "google",
      provider_account_id: "broken_id",
      status: "inactive"
    )

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    assert_text "working@gmail.com"
    assert_text "broken@gmail.com"
    assert_text "ACTIVE"
    assert_text "INACTIVE"
  end
end
