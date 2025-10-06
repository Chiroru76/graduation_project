class CharacterAppearance < ApplicationRecord
  belongs_to :character_kind

  enum pose: { idle: 0, sleep: 1, happy: 2 }
  enum asset_kind: { webp: 0, png: 1 }

  validates :pose, presence: true, uniqueness: { scope: :character_kind_id }
  validates :asset_kind, presence: true


end
