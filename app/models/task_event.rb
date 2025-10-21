class TaskEvent < ApplicationRecord
  belongs_to :user
  belongs_to :task
  belongs_to :awarded_character, class_name: "Character", optional: true

  enum :kind, { todo: 0, habit: 1 }, default: :todo
  enum :action, { created: 0, completed: 1, reopened: 2, logged: 3 }

  validates :kind, :action, :delta, :occurred_at, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :xp_amount, numericality: true

end
