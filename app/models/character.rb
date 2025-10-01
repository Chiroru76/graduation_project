class Character < ApplicationRecord
  belongs_to :user
  belongs_to :character_kind
end
