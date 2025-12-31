require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  test "dashboard displays after login" do
    user = User.create!(email_address: "dashboard_test@example.com", password: "password", email_verified_at: Time.current)

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    assert_text "Dashboard"
  end

  test "dashboard shows current month label" do
    user = User.create!(email_address: "month_test@example.com", password: "password", email_verified_at: Time.current)

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    current_month = Date.current.strftime("%B").upcase
    assert_text current_month
  end

  test "can navigate to transactions from dashboard" do
    user = User.create!(email_address: "nav_test@example.com", password: "password", email_verified_at: Time.current)

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    click_link "Transactions"
    assert_current_path transactions_path
  end

  test "can navigate to emails from dashboard" do
    user = User.create!(email_address: "nav_email_test@example.com", password: "password", email_verified_at: Time.current)

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    click_link "Emails"
    assert_current_path emails_path
  end
end
