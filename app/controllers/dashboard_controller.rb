class DashboardController < ApplicationController
  def show
    @tasks = current_user.tasks.order(:created_at)
  end
end
