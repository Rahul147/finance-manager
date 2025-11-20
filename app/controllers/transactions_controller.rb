class TransactionsController < ApplicationController
  def index
    scoped_transactions = transactions_scope

    @transactions = scoped_transactions
      .includes(:email)
      .ordered_newest
    @metrics = TransactionMetrics.new(scoped_transactions)

    render :index, layout: false if turbo_frame_request?
  end

  def show
    @transaction = transactions_scope
      .includes(:email)
      .find(params[:id])
  end

  private

  def transactions_scope
    @transactions_scope ||= Transaction
      .for_user(Current.user.id)
      .search(params[:q])
  end
end
