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
    @task = current_user.tasks.new(kind: kind, tracking_mode: (kind == "habit" ? :checkbox : nil))
  end

  def create
    @task = current_user.tasks.new(task_create_params)
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
    if @task.update(task_update_params)
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
    # 数量ログ型の習慣は complete を禁止して、数量記録フォームへ誘導
    if @task.habit? && @task.log?
      return redirect_to dashboard_show_path, alert: "この習慣は数量ログで記録してください"
    end

    # 進化/孵化の判定用スナップショット
    character     = current_user.active_character
    before_level  = character&.level
    before_stage  = character&.character_kind&.stage # "egg" | "child" | "adult"

    completed = false
    notice = nil

    if @task.habit?&& @task.open?
      @task.complete!(by_user: current_user)
      completed = true
      notice = "習慣を完了しました"
    elsif @task.habit? && @task.done?
      @task.reopen!(by_user: current_user)
      notice = "習慣を未完了に戻しました"
    elsif @task.todo?
      @task.complete!(by_user: current_user)
      completed = true
      notice = "TODOを完了しました"
    end

    # タスク完了時のペットコメント生成
    if completed
      pet_comment = PetComments::Generator.for(
        :task_completed,
        user: current_user,
        context: {
          task_title: @task.title,
          difficulty: @task.difficulty
        }
      )
      flash[:pet_comment] = pet_comment if pet_comment.present?
    end

    # 更新後を読みにいく（キャラがいれば）
    character&.reload
    after_level = character&.level
    after_stage = character&.character_kind&.stage

    # 3) 判定 （進化 or 孵化）
    @hatched = (before_stage == "egg"   && after_stage == "child" && before_level == 1  && after_level == 2)
    @evolved  = (before_stage == "child" && after_stage == "adult" && before_level == 9 && after_level == 10)

    @appearance = CharacterAppearance.find_by(character_kind: character.character_kind, pose: :idle)

    if @evolved
      return redirect_to share_evolved_path(current_user), notice: "ペットが進化しました！シェアしよう！"
    elsif @hatched
      return redirect_to share_hatched_path(current_user), notice: "ペットが孵化しました！シェアしよう！"
    end

    # 6) 称号判定（完了時のみ）
    unlocked_titles = completed ? Titles::Unlocker.new(user: current_user).call : []

    respond_to do |format|
      format.html do
        redirect_to dashboard_show_path, notice: notice
      end

      format.turbo_stream do
        flash.now[:notice] = notice
        flash.now[:pet_comment] = flash[:pet_comment] if flash[:pet_comment]
        @unlocked_titles = unlocked_titles
      end
    end
  end

  # ✅ 数量ログ型: 1回のログにつき reward_exp を固定付与して履歴を残す
  def log_amount
    @task = current_user.tasks.find(params[:id]) unless defined?(@task)
    return head :unprocessable_entity unless @task.habit? && @task.log?

    # 進化/孵化の判定用スナップショット
    character     = current_user.active_character
    before_level  = character&.level
    before_stage  = character&.character_kind&.stage # "egg" | "child" | "adult"

    qty  = (BigDecimal(params[:amount].to_s) rescue 0)
    unit = params[:unit].presence || @task.target_unit

    @task.log!(by_user: current_user, amount: qty, unit: unit)

    # 更新後を読みにいく
    character&.reload
    after_level = character&.level
    after_stage = character&.character_kind&.stage

    # 3) 判定 （進化 or 孵化）
    hatched = (before_stage == "egg"   && after_stage == "child" && before_level == 1  && after_level == 2)
    evolved = (before_stage == "child" && after_stage == "adult" && before_level == 9 && after_level == 10)

    @appearance = CharacterAppearance.find_by(character_kind: character.character_kind, pose: :idle)

    respond_to do |f|
      f.html { redirect_to dashboard_show_path, notice: "記録しました" }
      f.turbo_stream { render locals: { hatched: hatched, evolved: evolved } }
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to dashboard_show_path, alert: "記録に失敗しました: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    Rails.logger.error("[Tasks#log_amount] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    redirect_to dashboard_show_path, alert: "想定外のエラーが発生しました"
  end


  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  # 作成時は tracking_mode を許可（habit の時だけ意味を持つ）
  def task_create_params
    params.require(:task).permit(
      :title, :kind, :due_on,
      :reward_exp, :reward_food_count,
      :difficulty, :target_value, :target_unit, :target_period, :tag,
      :tracking_mode,
      repeat_rule: { days: [] }
    ).tap { |p| p[:repeat_rule] ||= {} }
  end

  # 更新時は方式変更を禁止（MVPでは tracking_mode は受け取らない）
  def task_update_params
    params.require(:task).permit(
      :title, :due_on,
      :reward_exp, :reward_food_count,
      :difficulty, :target_value, :target_unit, :target_period, :tag,
      repeat_rule: { days: [] }
    ).tap { |p| p[:repeat_rule] ||= {} }
  end
end
