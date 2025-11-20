# app/controllers/emails_controller.rb
class EmailsController < ApplicationController
  def index
    @emails = emails_scope
      .includes(:financial_transaction)
      .ordered_newest
    @metrics = EmailMetrics.new(emails_scope)

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
