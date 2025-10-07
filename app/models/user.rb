class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :tasks, dependent: :destroy
  # 所有しているキャラクター一覧をuser.charactersで参照できる
  has_many :characters
  # 現在育成中のキャラクターをuser.active_characterで参照できる
  belongs_to :active_character, class_name: "Character", foreign_key: "character_id", optional: true
  # ユーザー作成後にキャラクター作成メソッドを呼ぶ
  after_create_commit :create_initial_character

  private
  def create_initial_character
    egg_kind = CharacterKind.find_by!(asset_key: "egg", stage: 0)
    ch = characters.create!(character_kind: egg_kind, state: :alive, stage: :egg)
    update!(active_character: ch)
  end
end
