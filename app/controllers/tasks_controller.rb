class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :show, :edit, :update, :destroy, :complete ]

  def index
    @tasks = current_user.tasks.order(created_at: :desc)
  end

  def show
  end

  def new
    # クエリパラメータ kind を読んで、"todo" か "habit" だけを許可
    kind = params[:kind].to_s.presence_in(%w[todo habit]) || "todo"
    @task = current_user.tasks.new(kind: kind)
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

  def complete
    if @task.open?
        @task.update(status: :done, completed_at: Time.current)
        notice = "TODOを完了しました"
    else
        @task.update(status: :open, completed_at: nil)
        notice = "TODOを未完了に戻しました"
    end

    # キャラクター誕生判定（条件：レベル1→2にレベルアップ）
    character = current_user.active_character
    hatched = character.saved_change_to_level? && character.level_previously_was == 1 && character.level == 2
    character.reload
    @appearance = CharacterAppearance.find_by(character_kind: character.character_kind, pose: :idle)

    respond_to do |format|
        format.html { redirect_to dashboard_show_path, notice: notice }
        # ビューにローカル変数hatchedを渡す
        format.turbo_stream { render locals: { hatched: hatched } }
    end
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(
      :title, :kind, :status, :due_on,
      :reward_exp, :reward_food_count, :completed_at,
      :difficulty, :target_value, :target_unit, :target_period, :tag,
      repeat_rule: { days: [] }
    ).tap do |p|  # ← StrongParams の結果を p に渡して後処理する
      p[:repeat_rule] ||= {}   # ← repeat_rule が nil のときは {} にしておく
    end
  end
end
