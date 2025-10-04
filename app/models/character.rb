class Character < ApplicationRecord
  belongs_to :user
  belongs_to :character_kind

  enum :state, { alive: 0, dead: 1 }
  enum :stage, { egg: 0, child: 1, adult: 2 }

  validates :level, numericality: { greater_than_or_equal_to: 1 }
  validates :exp, :bond_hp, :bond_hp_max, numericality: { greater_than_or_equal_to: 0 }
  validates :bond_hp, numericality: { less_than_or_equal_to: :bond_hp_max }
end
