class DashboardController < ApplicationController
  before_action :authenticate_user!
  def show
    @tasks = current_user.tasks.order(:created_at)
  end
end
