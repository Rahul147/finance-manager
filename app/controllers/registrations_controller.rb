class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    redirect_to root_path if authenticated?
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      if Rails.env.development?
        token = @user.generate_token_for(:email_verification)
        puts ""
        puts "=" * 60
        puts "VERIFICATION EMAIL for #{@user.email_address}"
        puts "http://localhost:3000/email_verification?token=#{token}"
        puts "=" * 60
        puts ""
      end
      EmailVerificationMailer.verification(@user).deliver_later
      redirect_to new_session_path, notice: "Account created! Check your email (or server logs) to verify."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
