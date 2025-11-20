# app/controllers/emails_controller.rb
class EmailsController < ApplicationController
  def index
    scope = Email
      .where(user_id: Current.user.id)
      .includes(:financial_transaction)

    if (q = params[:q].to_s.strip).present?
      pattern = "%#{q.downcase}%"
      scope = scope.where(
        "LOWER(subject) LIKE :pattern OR LOWER(from_address) LIKE :pattern OR LOWER(snippet) LIKE :pattern",
        pattern: pattern
      )
    end

    @emails = scope.order(sent_at: :desc, created_at: :desc)

    render :index, layout: false if turbo_frame_request?
  end

  def show
    @email = Email.where(user_id: Current.user.id).find(params[:id])
  end
end
