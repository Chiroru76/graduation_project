class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :show, :edit, :update, :destroy ]

  def index
    @tasks = current_user.tasks.order(created_at: :desc)
  end

  def show
  end

  def new
    # クエリパラメータ kind を読んで、"todo" か "habit" だけを許可
    kind = params[:kind].to_s.presence_in(%w[todo habit]) || "todo"
    @task = current_user.tasks.new(kind: params[:kind]|| :todo)
  end

  def create
    @task = current_user.tasks.new(task_params)
    if @task.save
        message =
        if @task.todo?
            "TODOを作成しました"
        elsif @task.habit?
            "習慣を作成ました"
        end
        redirect_to dashboard_show_path, notice: message
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
    if @task.destroy
        redirect_to dashboard_show_path, notice: "TODOを削除しました"
    else
        flash.now[:alert] = "TODOを削除できませんでした"
        render :edit, status: :unprocessable_entity
    end
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
