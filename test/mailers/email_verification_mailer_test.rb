require "test_helper"

class EmailVerificationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  test "verification sends to correct recipient" do
    mail = EmailVerificationMailer.verification(@user)

    assert_equal [ @user.email_address ], mail.to
    assert_equal "Verify your email address", mail.subject
  end

  test "verification includes verification link in body" do
    mail = EmailVerificationMailer.verification(@user)
    body = mail.body.encoded

    assert_match(/email_verification/, body)
    assert_match(/token=/, body)
  end

  test "verification includes expiration notice" do
    mail = EmailVerificationMailer.verification(@user)
    body = mail.body.encoded

    # Should mention expiration time
    assert_match(/24 hours/i, body)
  end

  test "verification generates both html and text parts" do
    mail = EmailVerificationMailer.verification(@user)

    assert mail.multipart?
    assert mail.html_part.present?
    assert mail.text_part.present?
  end
end
