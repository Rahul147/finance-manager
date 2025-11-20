# app/controllers/emails_controller.rb
class EmailsController < ApplicationController
  def index
    scoped_emails = emails_scope

    @emails = scoped_emails
      .includes(:financial_transaction)
      .ordered_newest
    @metrics = EmailMetrics.new(scoped_emails)

    render :index, layout: false if turbo_frame_request?
  end

  def show
    @email = Email
      .for_user(Current.user.id)
      .includes(:financial_transaction)
      .find(params[:id])
  end

  private

  def emails_scope
    @emails_scope ||= Email
      .for_user(Current.user.id)
      .search(params[:q])
  end
end
