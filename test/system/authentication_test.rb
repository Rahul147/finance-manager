require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "visiting root without authentication redirects to login" do
    visit root_url
    assert_current_path new_session_path
    assert_text "Welcome Back"
  end

  test "user can log in with valid credentials" do
    user = User.create!(email_address: "system_test@example.com", password: "password")

    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Login"

    assert_current_path root_path
    assert_text "Dashboard"
  end

  test "user sees error with invalid credentials" do
    visit new_session_url
    fill_in "email_address", with: "wrong@example.com"
    fill_in "password", with: "wrongpassword"
    click_button "Login"

    assert_text "Try another email address or password"
  end

  test "password reset flow from login page" do
    visit new_session_url
    click_link "Forgot password?"
    assert_current_path new_password_path
    assert_text "Forgot your password?"
  end
end
