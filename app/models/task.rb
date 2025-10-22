class Task < ApplicationRecord
  belongs_to :user

  enum :kind, { todo: 0, habit: 1 }, default: :todo
  enum :status, { open: 0, done: 1, archived: 2 }, default: :open
  enum :difficulty, { easy: 0, normal: 1, hard: 2 }, default: :easy
  enum :target_unit, { times: 0, km: 1, minutes: 2 }
  enum :target_period, { daily: 0, weekly: 1, monthly: 2 }

  has_many :task_events, dependent: :destroy

  # 難易度応じた経験値を定義（要調整）
  REWARD_EXP_BY_DIFFICULTY = {
    "easy"   => 10,
    "normal" => 20,
    "hard"   => 40
  }.freeze
  # 難易度に応じて経験値を自動設定
  before_validation :assign_reward_exp_by_difficulty

  # statusがdoneに変化した時に実行
  after_update :give_exp_to_active_character, :give_food_to_user, if: -> { saved_change_to_status? && done? }

  validates :title, presence: true, length: { maximum: 255 }
  validates :difficulty, presence: true
  validates :reward_exp, numericality: { greater_than_or_equal_to: 0 }
  validates :reward_food_count, numericality: { greater_than_or_equal_to: 0 }

  # 作成イベントを明示で残すメソッド
  def log_created!(by_user:)
    task_events.create!(
      user: by_user,
      kind: self[:kind],           # スナップショットとして整数値を固定
      action: :created,
      delta: 0,
      amount: 0,
      xp_amount: 0,
      occurred_at: Time.current
    )
  end

  # ---- 完了処理（状態変更 + イベント + 必要ならXP付与）----
  def complete!(by_user:, amount: 0, unit: nil, award_exp: true)
    return self if done? # 二重押下対策（MVP：雑に弾く）

    ApplicationRecord.transaction do
      update!(status: :done, completed_at: Time.current)

      awarded = by_user.active_character
      xp = reward_exp.to_i

      # MVPでは「XP付与はここでやる」or「あとで集計して付与」に切替可能
      awarded&.gain_exp!(xp) if award_exp && xp.positive?

      task_events.create!(
        user: by_user,
        kind: self[:kind],
        action: :completed,
        delta: 1,
        amount: amount.to_d, # habitなら数量、todoは0でOK
        unit: unit,
        xp_amount: xp,
        awarded_character: awarded,
        occurred_at: Time.current
      )
    end

    self
  end

  # ---- 取り消し（openへ戻す + イベント。XP相殺もここで）----
  def reopen!(by_user:, revert_exp: true)
    return self if open?

    ApplicationRecord.transaction do
      update!(status: :open, completed_at: nil)

      awarded = by_user.active_character
      xp_cancel = -reward_exp.to_i

      # MVPでは簡単に“相殺”だけ。減算ロジックが無ければスキップ可
      if revert_exp && xp_cancel.negative? && awarded&.respond_to?(:decrease_exp!)
        awarded.decrease_exp!(xp_cancel.abs)
      end

      task_events.create!(
        user: by_user,
        kind: self[:kind],
        action: :reopened,
        delta: -1,
        amount: 0,
        xp_amount: xp_cancel,
        awarded_character: awarded,
        occurred_at: Time.current
      )
    end

    self
  end

  private

  def assign_reward_exp_by_difficulty
    return if difficulty.blank?
    # 難易度が変更または未設定の際に経験値を計算
    if will_save_change_to_difficulty? || reward_exp.blank?
      self.reward_exp = REWARD_EXP_BY_DIFFICULTY.fetch(difficulty.to_s, 0)
    end
  end

  def give_exp_to_active_character
    character = user.active_character
    return unless character.present?
    # 経験値を加算(Characterモデルのgain_expメソッドを呼び出し)
    character.gain_exp!(reward_exp)
  end

  def give_food_to_user
    user.increment!(:food_count, reward_food_count)
  end
end
