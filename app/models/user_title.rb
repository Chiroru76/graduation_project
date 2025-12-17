class UserTitle < ApplicationRecord
  belongs_to :user
  belongs_to :title

  validates :unlocked_at, presence: true
end
