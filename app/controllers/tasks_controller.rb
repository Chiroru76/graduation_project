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
      # 作成イベントを明示で残す
      @task.log_created!(by_user: current_user)

      notice = @task.todo? ? "TODOを作成しました" : "習慣を作成しました"
      redirect_to dashboard_show_path, notice: notice
    else
      flash.now[:alert] = @task.errors.full_messages.join("\n")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      notice = @task.todo? ? "TODOを更新しました" : "習慣を更新しました"
      redirect_to dashboard_show_path, notice: notice
    else
      flash.now[:alert] = @task.errors.full_messages.join("\n")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      notice = @task.todo? ? "TODOを削除しました" : "習慣を削除しました"
      redirect_to dashboard_show_path, notice: notice
    else
      flash.now[:alert] = "削除できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end


  def complete
    # 1) 更新前スナップショット
    character = current_user.active_character
    before_level = character.level
    before_stage = character.character_kind.stage # "egg" | "child" | "adult"

    if @task.open?
      # habit のときだけ数量/単位を使う（todoは 0/ nil）
      amount, unit = completion_amount_and_unit_for(@task)

      @task.complete!(
        by_user: current_user,
        amount: amount,
        unit: unit
      )
      notice = @task.todo? ? "TODOを完了しました" : "習慣を完了しました"
    else
      @task.reopen!(by_user: current_user)
      notice = @task.todo? ? "TODOを未完了に戻しました" : "習慣を未完了に戻しました"
    end

  # 2) 更新後を読みにいく
  character.reload
  after_level = character.level
  after_stage = character.character_kind.stage

  # 3) 判定 （進化 or 孵化）
  hatched = (before_stage == "egg"   && after_stage == "child" && before_level == 1  && after_level == 2)
  evolved = (before_stage == "child" && after_stage == "adult" && before_level == 9 && after_level == 10)

  @appearance = CharacterAppearance.find_by(character_kind: character.character_kind, pose: :idle)


    respond_to do |format|
        format.html { redirect_to dashboard_show_path, notice: notice }
        # 4) フラグをビューに渡す
        format.turbo_stream { render locals: { hatched: hatched, evolved: evolved } }
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

  # habit のみ完了処理時の“数量”と“単位”を整理して返す
  def completion_amount_and_unit_for(task)
    if task.habit?
      amount = params[:amount].presence || 0
      unit   = params[:unit].presence
      [amount.to_d, unit]
    else
      [0.to_d, nil]
    end
  end
end
