class ChartsController < ApplicationController
  before_action :authenticate_user!

  def show
    # 日数パラメータ取得（7日 or 30日）
    @days = (%w[7 30].include?(params[:range]) ? params[:range].to_i : 7)
    range = @days.days.ago.to_date..Date.current

    @tasks = current_user.tasks.order(created_at: :desc)

    # TODO完了数（日別）
    @todo_completed = TaskEvent.where(user: current_user, task_kind: :todo, action: :completed)
      .group_by_day(:occurred_at, range: range)
      .count

    # 習慣完了・ログ数（日別）
    @habit_done = TaskEvent.where(user: current_user, task_kind: :habit, action: [:completed, :logged])
      .group_by_day(:occurred_at, range: range)
      .count

    # --- 習慣の数量ロググラフ用 ---
    log_range = 7.days.ago.beginning_of_day..Time.zone.now

    # ログ型習慣のTaskEvent
    log_events = TaskEvent.where(user_id: current_user.id, task_kind: :habit, action: :logged, occurred_at: log_range)

    # タスクメタ情報（タイトルはTaskテーブルから、単位は最新のTaskEventから取得）
    task_ids = log_events.distinct.pluck(:task_id)
    tasks = Task.where(id: task_ids).index_by(&:id)

    # 各タスクの最新のログイベントのunitを一括取得（サブクエリで最新のoccurred_atを取得）
    latest_event_units = TaskEvent
      .where(user_id: current_user.id, task_kind: :habit, action: :logged, task_id: task_ids)
      .select('DISTINCT ON (task_id) task_id, unit')
      .order('task_id, occurred_at DESC')
      .index_by(&:task_id)

    @task_meta = task_ids.to_h do |tid|
      task = tasks[tid]
      latest_event = latest_event_units[tid]
      unit = latest_event&.unit.presence || task&.target_unit.presence || "数量"

      [tid, { title: task&.title || "不明なタスク", unit: unit }]
    end

    # 日別×タスクごとの合計値
    raw = log_events.group_by_day(:occurred_at, range: log_range)
      .group(:task_id)
      .sum(:amount) # { [Date, task_id] => 合計 }

    # 整形: { task_id => { date => 合計 } }
    @series_by_task = Hash.new { |h, k| h[k] = {} }
    raw.each do |(date, tid), sum|
      @series_by_task[tid][date] = sum
    end

    # 全期間合計値
    @total_by_task = log_events.group(:task_id).sum(:amount)

    raw_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Time.zone.today
    @start_date = raw_date.beginning_of_month
    @all_events = current_user.task_events.where(action: :completed)

    respond_to do |format|
      format.html

      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "calendar",
          partial: "calendar"
        )
      end
    end

    render :show
  end
end
