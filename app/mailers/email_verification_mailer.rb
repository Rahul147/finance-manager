class EmailVerificationMailer < ApplicationMailer
  def verification(user)
    @user = user
    mail subject: "Verify your email address", to: user.email_address
  end
end
