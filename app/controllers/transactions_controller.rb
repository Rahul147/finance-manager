class TransactionsController < ApplicationController
  def index
    scoped_transactions = filtered_transactions_scope

    @transactions = scoped_transactions
      .includes(:email)
      .ordered_newest
    @metrics = TransactionMetrics.new(scoped_transactions)
    @selected_transaction_type = transaction_type_filter

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
        format.html { redirect_to transactions_path, notice: "Transaction updated." }
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
        format.html { redirect_to transactions_path, alert: "Unable to update transaction." }
      end
    end
  end

  private

  def base_transactions_scope
    @base_transactions_scope ||= Transaction.for_user(Current.user.id)
  end

  def filtered_transactions_scope
    scope = base_transactions_scope
    scope = scope.search(params[:q])
    return scope unless transaction_type_filter

    scope.where(transaction_type: Transaction.transaction_types[transaction_type_filter])
  end

  def transaction_type_filter
    return @transaction_type_filter if defined?(@transaction_type_filter)

    type_param = params[:transaction_type].to_s.strip
    @transaction_type_filter =
      if type_param.present? && Transaction.transaction_types.key?(type_param)
        type_param
      else
        nil
      end
  end

  def transaction_params
    params.require(:transaction).permit(:category, :transaction_type)
  end
end
