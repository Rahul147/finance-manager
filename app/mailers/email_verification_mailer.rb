class EmailVerificationMailer < ApplicationMailer
  def verification(user)
    @user = user
    @verification_url = email_verification_url(token: user.generate_token_for(:email_verification))

    if Rails.env.development?
      puts ""
      puts "=" * 60
      puts "VERIFICATION EMAIL for #{user.email_address}"
      puts @verification_url
      puts "=" * 60
      puts ""
    end

    mail subject: "Verify your email address", to: user.email_address
  end
end
