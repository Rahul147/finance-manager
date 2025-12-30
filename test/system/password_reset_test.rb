require "application_system_test_case"

class PasswordResetTest < ApplicationSystemTestCase
  test "visiting password reset request page" do
    visit new_password_url
    assert_text "Forgot your password?"
  end

  test "requesting password reset shows confirmation" do
    user = User.create!(email_address: "reset_test@example.com", password: "password")

    visit new_password_url
    fill_in "email_address", with: user.email_address
    click_button "Email reset instructions"

    # Should redirect to login page
    assert_current_path new_session_path
  end

  test "password reset flow from login page" do
    visit new_session_url
    click_link "Forgot password?"

    assert_current_path new_password_path
    assert_text "Forgot your password?"
  end
end
