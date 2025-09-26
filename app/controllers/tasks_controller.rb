class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    @tasks = current_user.tasks.order(created_at: :desc)
  end

  def show
  end

  def new
    @task = current_user.tasks.new
  end

  def create
    @task = current_user.tasks.new(task_prams)
    if @task.save
        redirect_to dashboard_show_path, notice: "タスクを作成しました"
    else
        render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def set_task
    @task = current_user.tasks.find(prams[ :id ])
  end

  def task_prams
    prams.require(:task).permit(:title, :kind, :status, :due_on, :repeat_rule,
                                :reward_exp, :reward_food_count, :completed_at,
                                :difficulty, :target_value, :target_unit, :target_period, :tag)
  end


end
