class TransactionsController < ApplicationController
  def index
    scope = Transaction
      .where(user_id: Current.user.id)
      .includes(:email)

    if (q = params[:q].to_s.strip).present?
      pattern = "%#{q.downcase}%"
      scope   = scope.where(
        "LOWER(merchant) LIKE ? OR LOWER(category) LIKE ? OR LOWER(notes) LIKE ?",
        pattern, pattern, pattern
      )
    end

    @transactions = scope
      .order(transaction_date: :desc, created_at: :desc)

    if turbo_frame_request?
      render :index, layout: false
    end
  end

  def show
    @transaction = Transaction
      .where(user_id: Current.user.id)
      .includes(:email)
      .find(params[:id])
  end
end
