class CharacterKind < ApplicationRecord
    has_many :characters

    validates :name, presence: true, uniqueness: true
    validates :stage, presence: true

    enum :stage, { egg: 0, child: 1, adult: 2 }

end
