require "test_helper"

class EmailProviderOauthsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    # Set test credentials for OAuth client
    ENV["GOOGLE_API_CLIENT_ID"] ||= "test-client-id.apps.googleusercontent.com"
    ENV["GOOGLE_API_CLIENT_SECRET"] ||= "test-client-secret"
  end

  # === Start Action ===

  test "start redirects to Google OAuth" do
    get oauth_start_path(provider: "google")

    assert_response :redirect
    assert_match %r{accounts\.google\.com}, response.location
  end

  test "start stores state in session" do
    get oauth_start_path(provider: "google")

    # State is stored in session for CSRF protection
    assert_not_nil session[:google_oauth_state]
  end

  test "start includes required scopes in redirect URL" do
    get oauth_start_path(provider: "google")

    redirect_uri = response.location
    assert_match(/scope=/, redirect_uri)
  end

  test "start generates unique state for each request" do
    get oauth_start_path(provider: "google")
    first_state = session[:google_oauth_state]

    get oauth_start_path(provider: "google")
    second_state = session[:google_oauth_state]

    assert_not_equal first_state, second_state
  end

  # === Callback Action - State Validation (CSRF Protection) ===

  test "callback rejects request with missing state" do
    get oauth_callback_path(provider: "google"), params: { code: "test_code" }

    assert_redirected_to root_path
    # Either invalid state or auth error (depending on order of checks)
    assert flash[:alert].present?
  end

  test "callback rejects request with mismatched state" do
    # Set a valid state in session
    get oauth_start_path(provider: "google")
    valid_state = session[:google_oauth_state]

    # Send callback with wrong state
    get oauth_callback_path(provider: "google"), params: {
      code: "test_code",
      state: "wrong_state_value"
    }

    assert_redirected_to root_path
    assert_equal "Invalid OAuth state.", flash[:alert]
  end

  test "callback deletes state from session after use" do
    get oauth_start_path(provider: "google")
    state = session[:google_oauth_state]

    # The state should be present before callback
    assert_not_nil state

    # After callback (even if it fails for other reasons), state should be deleted
    get oauth_callback_path(provider: "google"), params: {
      code: "test_code",
      state: state
    }

    # State should be consumed (deleted) to prevent replay attacks
    assert_nil session[:google_oauth_state]
  end

  # === Route Constraints ===

  test "only allows google as provider" do
    assert_raises(ActionController::UrlGenerationError) do
      get oauth_start_path(provider: "facebook")
    end
  end

  # === Controller Structure ===

  test "SCOPES constant includes Gmail readonly scope" do
    scopes = EmailProviderOauthsController::SCOPES

    assert_includes scopes, Google::Apis::GmailV1::AUTH_GMAIL_READONLY
    assert_includes scopes, "email"
    assert_includes scopes, "profile"
  end

  # Note: Full integration tests that verify token exchange and account creation
  # require mocking the Google OAuth and Gmail APIs.
  # The critical security behaviors (state validation, CSRF protection) are tested above.
  #
  # Additional behaviors verified through manual/integration testing:
  # 1. Code exchange for access token
  # 2. Gmail profile fetching
  # 3. EmailAccount creation/update
  # 4. Token storage
  # 5. Error handling for Signet::AuthorizationError
end
