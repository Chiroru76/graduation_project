class DashboardController < ApplicationController
  before_action :authenticate_user!
  def show
    @todos = current_user.tasks.todo.order(:created_at)
    @habits = current_user.tasks.habit.order(:created_at)
  end
end
