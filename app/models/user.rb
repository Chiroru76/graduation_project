class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :tasks, dependent: :destroy
  # 所有しているキャラクター一覧をuser.charactersで参照できる
  has_many :characters
  #現在育成中のキャラクターをuser.active_characterで参照できる
  belongs_to :active_character, class_name: "Character", optional: true
end
