class Title < ApplicationRecord
  has_many :user_titles, dependent: :destroy
  has_many :users, through: :user_titles

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :rule_type, presence: true
  validates :threshold, presence: true, numericality: { greater_than: 0 }
end
