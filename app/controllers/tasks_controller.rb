class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :show, :edit, :update, :destroy ]

  def index
    @tasks = current_user.tasks.order(created_at: :desc)
  end

  def show
  end

  def new
    @task = current_user.tasks.new
  end

  def create
    @task = current_user.tasks.new(task_params)
    if @task.save
        redirect_to dashboard_show_path, notice: "TODOを作成しました"
    else
        flash.now[:alert] = @task.errors.full_messages
        render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
        redirect_to dashboard_show_path, notice: "TODOを更新しました"
    else
        flash.now[:alert] = @task.errors.full_messages
        render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :kind, :status, :due_on, :repeat_rule,
                                :reward_exp, :reward_food_count, :completed_at,
                                :difficulty, :target_value, :target_unit, :target_period, :tag)
  end
end
