class TransactionsController < ApplicationController
  def index
    @transactions = Transaction
      .where(user_id: Current.user.id)
      .includes(:email)
      .order(transaction_date: :desc, created_at: :desc)
  end

  def show
    @transaction = Transaction
      .where(user_id: Current.user.id)
      .includes(:email)
      .find(params[:id])
  end
end