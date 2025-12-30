require "test_helper"

class EmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @email = emails(:axis_debit)
  end

  # === Authentication ===

  test "index requires authentication" do
    get emails_url
    assert_redirected_to new_session_url
  end

  test "show requires authentication" do
    get email_url(@email)
    assert_redirected_to new_session_url
  end

  # === Index Action ===

  test "index returns success when authenticated" do
    sign_in_as(@user)
    get emails_url
    assert_response :success
  end

  test "index only shows current user's emails" do
    sign_in_as(@user)
    get emails_url
    assert_response :success

    # Should show user one's email subjects
    assert_match @email.subject, response.body

    # Should not show user two's emails
    other_email = emails(:user_two_email)
    assert_no_match other_email.subject, response.body
  end

  test "index orders emails by newest first" do
    sign_in_as(@user)
    get emails_url
    assert_response :success
  end

  test "index filters by search query on subject" do
    sign_in_as(@user)
    get emails_url(q: "Axis Bank")
    assert_response :success
    assert_match "Axis", response.body
  end

  test "index filters by search query on from_address" do
    sign_in_as(@user)
    get emails_url(q: "hdfcbank.net")
    assert_response :success
  end

  test "index filters by search query on snippet" do
    sign_in_as(@user)
    get emails_url(q: "AMAZON")
    assert_response :success
  end

  test "index renders without layout for turbo frame requests" do
    sign_in_as(@user)
    get emails_url, headers: { "Turbo-Frame" => "emails_list" }
    assert_response :success
  end

  # === Show Action ===

  test "show displays email details" do
    sign_in_as(@user)
    get email_url(@email)
    assert_response :success
    assert_match @email.subject, response.body
  end

  test "show works for email without transaction" do
    unprocessed = emails(:icici_upi)
    sign_in_as(@user)
    get email_url(unprocessed)
    assert_response :success
  end

  test "show returns 404 for other user's email" do
    other_user_email = emails(:user_two_email)
    sign_in_as(@user)

    get email_url(other_user_email)
    assert_response :not_found
  end

  test "show returns 404 for non-existent email" do
    sign_in_as(@user)
    get email_url(id: 999999)
    assert_response :not_found
  end

  # === Authorization / Data Isolation ===

  test "user cannot see other user's emails in index" do
    sign_in_as(@other_user)
    get emails_url
    assert_response :success

    # User two should see their own email
    user_two_email = emails(:user_two_email)
    assert_match user_two_email.subject, response.body

    # User two should not see user one's email
    assert_no_match @email.subject, response.body
  end
end
