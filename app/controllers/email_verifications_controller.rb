class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 3.minutes, only: :create, with: -> { redirect_to new_email_verification_path, alert: "Try again later." }

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user.nil?
      redirect_to new_session_path, alert: "Verification link is invalid or has expired."
    elsif user.email_verified?
      redirect_to new_session_path, notice: "Email already verified. Please sign in."
    else
      user.mark_as_verified!
      redirect_to new_session_path, notice: "Email verified successfully! Please sign in."
    end
  end

  def new
  end

  def create
    if (user = User.find_by(email_address: params[:email_address]))
      unless user.email_verified?
        if Rails.env.development?
          token = user.generate_token_for(:email_verification)
          puts ""
          puts "=" * 60
          puts "VERIFICATION EMAIL for #{user.email_address}"
          puts "http://localhost:3000/email_verification?token=#{token}"
          puts "=" * 60
          puts ""
        end
        EmailVerificationMailer.verification(user).deliver_later
      end
    end

    redirect_to new_session_path, notice: "If an account exists with that email, verification instructions have been sent."
  end
end
