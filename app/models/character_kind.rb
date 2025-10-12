class CharacterKind < ApplicationRecord
    has_many :characters

    validates :name, presence: true, uniqueness: { scope: :stage }
    validates :stage, presence: true
    validates :asset_key,  presence: true, uniqueness: { scope: :stage }

    enum :stage, { egg: 0, child: 1, adult: 2 }
end
