class DashboardsController < ApplicationController
  def index
    @summary = User::DashboardSummary.new(user: Current.user)
  end
end
