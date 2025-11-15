# app/controllers/emails_controller.rb
class EmailsController < ApplicationController
  def index
    @emails = Email.where(user_id: Current.user.id).order(sent_at: :desc)
  end

  def show
    @email = Email.where(user_id: Current.user.id).find(params[:id])
  end
end