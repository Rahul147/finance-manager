require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # === New Action ===

  test "new renders sign up form" do
    get new_registration_path

    assert_response :success
    assert_select "h1", "Create Account"
    assert_select "form[action=?]", registration_path
  end

  test "new redirects to root if already authenticated" do
    sign_in_as(users(:one))

    get new_registration_path

    assert_redirected_to root_path
  end

  # === Create Action ===

  test "create with valid params creates user and sends verification email" do
    assert_difference "User.count", 1 do
      assert_enqueued_emails 1 do
        post registration_path, params: {
          user: {
            email_address: "newuser@example.com",
            password: "securepassword123",
            password_confirmation: "securepassword123"
          }
        }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Account created! Check your email (or server logs) to verify.", flash[:notice]

    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert_not user.email_verified?
  end

  test "create with missing email renders form with errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "",
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action=?]", registration_path
  end

  test "create with missing password renders form with errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "",
          password_confirmation: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with mismatched passwords renders form with errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "password123",
          password_confirmation: "differentpassword"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with duplicate email renders form with errors" do
    existing_user = users(:one)

    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: existing_user.email_address,
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create normalizes email address" do
    post registration_path, params: {
      user: {
        email_address: "  UPPER@EXAMPLE.COM  ",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    }

    user = User.find_by(email_address: "upper@example.com")
    assert_not_nil user
  end

  test "create with invalid email format renders form with errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "not-an-email",
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Security ===

  test "new user cannot sign in without verification" do
    post registration_path, params: {
      user: {
        email_address: "unverified@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # Try to sign in
    post session_path, params: {
      email_address: "unverified@example.com",
      password: "password123"
    }

    assert_redirected_to new_email_verification_path
    assert_equal "Please verify your email address first.", flash[:alert]
  end
end
