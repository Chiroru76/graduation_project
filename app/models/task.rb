class Task < ApplicationRecord
  belongs_to :user

  enum :kind, { todo: 0, habit: 1 }, default: :todo
  enum :status, { open: 0, done: 1, archived: 2 }, default: :open
  enum :difficulty, { easy: 0, normal: 1, hard: 2 }, default: :easy
  enum :target_unit, { times: 0, km: 1, minutes: 2 }
  enum :target_period, { daily: 0, weekly: 1, monthly: 2 }

  # 難易度応じた経験値を定義（要調整）
  REWARD_EXP_BY_DIFFICULTY = {
    "easy"   => 10,
    "normal" => 20,
    "hard"   => 40
  }.freeze
  # 難易度に応じて経験値を自動設定
  before_validation :assign_reward_exp_by_difficulty

  validates :title, presence: true, length: { maximum: 255 }
  validates :difficulty, presence: true
  validates :reward_exp, numericality: { greater_than_or_equal_to: 0 }
  validates :reward_food_count, numericality: { greater_than_or_equal_to: 0 }

  private

  def assign_reward_exp_by_difficulty
    return if difficulty.blank?
    # 難易度が変更または未設定の際に経験値を計算
    if will_save_change_to_difficulty? || reward_exp.blank?
      self.reward_exp = REWARD_EXP_BY_DIFFICULTY.fetch(difficulty.to_s, 0)
    end
  end
end
