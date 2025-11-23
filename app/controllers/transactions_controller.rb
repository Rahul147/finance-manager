class TransactionsController < ApplicationController
  def index
    scoped_transactions = search_transactions_scope

    @transactions = scoped_transactions
      .includes(:email)
      .ordered_newest
    @metrics = TransactionMetrics.new(scoped_transactions)

    render :index, layout: false if turbo_frame_request?
  end

  def show
    @transaction = base_transactions_scope
      .includes(:email)
      .find(params[:id])
  end

  def update
    @transaction = base_transactions_scope.find(params[:id])

    respond_to do |format|
      if @transaction.update(transaction_params)
        format.turbo_stream
        format.html { redirect_to transactions_path, notice: "Category updated." }
      else
        format.turbo_stream do
          render(
            turbo_stream: turbo_stream.replace(
              helpers.dom_id(@transaction, :category_editor),
              partial: "transactions/category_editor",
              locals: { transaction: @transaction }
            ),
            status: :unprocessable_entity
          )
        end
        format.html { redirect_to transactions_path, alert: "Unable to update category." }
      end
    end
  end

  private

  def base_transactions_scope
    @base_transactions_scope ||= Transaction.for_user(Current.user.id)
  end

  def search_transactions_scope
    base_transactions_scope.search(params[:q])
  end

  def transaction_params
    params.require(:transaction).permit(:category)
  end
end
