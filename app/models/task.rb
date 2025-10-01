class Task < ApplicationRecord
  belongs_to :user

  enum :kind, { todo: 0, habit: 1 }, default: :todo
  enum :status, { open: 0, done: 1, archived: 2 }, default: :open
  enum :difficulty, { easy: 0, normal: 1, hard: 2 }, default: :easy
  enum :target_unit, { times: 0, km: 1, minutes: 2 }
  enum :target_period, { daily: 0, weekly: 1, monthly: 2 }

  validates :title, presence: true, length: { maximum: 255 }
  validates :difficulty, presence: true
  validates :reward_exp, numericality: { greater_than_or_equal_to: 0 }
  validates :reward_food_count, numericality: { greater_than_or_equal_to: 0 }
end
