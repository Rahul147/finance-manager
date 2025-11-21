class DashboardsController < ApplicationController
  def index
    @summary = DashboardSummary.new(user: Current.user)
  end
end
