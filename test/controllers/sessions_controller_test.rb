require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  # === Email Verification ===

  test "create blocks unverified user" do
    unverified = User.create!(
      email_address: "unverified@test.com",
      password: "password123"
    )

    post session_path, params: { email_address: unverified.email_address, password: "password123" }

    assert_redirected_to new_email_verification_path
    assert_equal "Please verify your email address first.", flash[:alert]
    assert_nil cookies[:session_id]
  end

  test "create allows verified user" do
    assert @user.email_verified?

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with wrong password does not reveal verification status" do
    unverified = User.create!(
      email_address: "unverified2@test.com",
      password: "password123"
    )

    post session_path, params: { email_address: unverified.email_address, password: "wrongpassword" }

    # Should show generic error, not verification status
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "new redirects to root if authenticated" do
    sign_in_as(@user)

    get new_session_path

    assert_redirected_to root_path
  end
end
