require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unverified_user = User.create!(
      email_address: "unverified@example.com",
      password: "password123",
      email_verified_at: nil
    )
  end

  # === Show Action (Verify Token) ===

  test "show with valid token verifies user" do
    token = @unverified_user.generate_token_for(:email_verification)

    assert_not @unverified_user.email_verified?

    get email_verification_path(token: token)

    assert_redirected_to new_session_path
    assert_equal "Email verified successfully! Please sign in.", flash[:notice]

    @unverified_user.reload
    assert @unverified_user.email_verified?
  end

  test "show with invalid token redirects with error" do
    get email_verification_path(token: "invalid_token")

    assert_redirected_to new_session_path
    assert_equal "Verification link is invalid or has expired.", flash[:alert]
  end

  test "show with expired token redirects with error" do
    token = @unverified_user.generate_token_for(:email_verification)

    # Simulate token expiration by traveling forward in time
    travel 25.hours do
      get email_verification_path(token: token)

      assert_redirected_to new_session_path
      assert_equal "Verification link is invalid or has expired.", flash[:alert]
    end
  end

  test "show with already verified user redirects with notice" do
    @unverified_user.mark_as_verified!
    token = @unverified_user.generate_token_for(:email_verification)

    get email_verification_path(token: token)

    assert_redirected_to new_session_path
    assert_equal "Email already verified. Please sign in.", flash[:notice]
  end

  # === New Action (Resend Form) ===

  test "new renders resend form" do
    get new_email_verification_path

    assert_response :success
    assert_select "h1", "Verify Email"
    assert_select "form[action=?]", email_verification_path
  end

  # === Create Action (Resend Email) ===

  test "create with valid unverified email sends verification" do
    assert_enqueued_emails 1 do
      post email_verification_path, params: { email_address: @unverified_user.email_address }
    end

    assert_redirected_to new_session_path
    assert_equal "If an account exists with that email, verification instructions have been sent.", flash[:notice]
  end

  test "create with verified email does not send verification" do
    verified_user = users(:one)
    assert verified_user.email_verified?

    assert_no_enqueued_emails do
      post email_verification_path, params: { email_address: verified_user.email_address }
    end

    assert_redirected_to new_session_path
    assert_equal "If an account exists with that email, verification instructions have been sent.", flash[:notice]
  end

  test "create with non-existent email does not reveal user existence" do
    assert_no_enqueued_emails do
      post email_verification_path, params: { email_address: "nonexistent@example.com" }
    end

    assert_redirected_to new_session_path
    # Same message regardless of whether email exists
    assert_equal "If an account exists with that email, verification instructions have been sent.", flash[:notice]
  end

  test "create normalizes email for lookup" do
    assert_enqueued_emails 1 do
      post email_verification_path, params: { email_address: "  UNVERIFIED@EXAMPLE.COM  " }
    end

    assert_redirected_to new_session_path
  end

  # === Token Security ===

  test "token cannot be used twice" do
    token = @unverified_user.generate_token_for(:email_verification)

    # First use succeeds
    get email_verification_path(token: token)
    assert_redirected_to new_session_path
    assert @unverified_user.reload.email_verified?

    # Second use shows already verified message
    get email_verification_path(token: token)
    assert_redirected_to new_session_path
    assert_equal "Email already verified. Please sign in.", flash[:notice]
  end

  test "show with empty token redirects with error" do
    get email_verification_path(token: "")

    assert_redirected_to new_session_path
    assert_equal "Verification link is invalid or has expired.", flash[:alert]
  end

  # === Session Controller Integration ===

  test "unverified user redirected to verification page on login" do
    post session_path, params: {
      email_address: @unverified_user.email_address,
      password: "password123"
    }

    assert_redirected_to new_email_verification_path
    assert_equal "Please verify your email address first.", flash[:alert]
  end

  test "verified user can sign in" do
    @unverified_user.mark_as_verified!

    post session_path, params: {
      email_address: @unverified_user.email_address,
      password: "password123"
    }

    assert_redirected_to root_path
  end
end
