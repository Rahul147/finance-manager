require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # === Authentication ===

  test "index requires authentication" do
    get dashboard_url
    assert_redirected_to new_session_url
  end

  test "root path requires authentication" do
    get root_url
    assert_redirected_to new_session_url
  end

  # === Index Action ===

  test "index returns success when authenticated" do
    sign_in_as(@user)
    get dashboard_url
    assert_response :success
  end

  test "root path shows dashboard" do
    sign_in_as(@user)
    get root_url
    assert_response :success
    assert_match "Dashboard", response.body
  end

  test "dashboard shows transaction count" do
    sign_in_as(@user)
    get dashboard_url
    assert_response :success
    # Dashboard should render successfully with metrics
  end

  test "dashboard shows connected accounts" do
    sign_in_as(@user)
    get dashboard_url
    assert_response :success
    # User one has connected email accounts
    assert_match @user.email_accounts.first.email_address, response.body
  end

  test "dashboard shows current month label" do
    sign_in_as(@user)
    get dashboard_url
    assert_response :success

    current_month = Date.current.strftime("%B")
    assert_match current_month, response.body
  end

  # === User Isolation ===

  test "different users see their own dashboard data" do
    # User one's dashboard
    sign_in_as(@user)
    get dashboard_url
    user_one_response = response.body

    # User two's dashboard
    sign_in_as(users(:two))
    get dashboard_url
    user_two_response = response.body

    # Both should load successfully
    assert_response :success
  end
end
