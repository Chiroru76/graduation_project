class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :line ]
  has_many :tasks, dependent: :destroy
  # 所有しているペット一覧をuser.charactersで参照できる
  has_many :characters, dependent: :destroy
  # 現在育成中のペットをuser.active_characterで参照できる
  belongs_to :active_character, class_name: "Character", foreign_key: "character_id", optional: true
  has_many :task_events, dependent: :destroy
  # ユーザー作成後にペット作成メソッドを呼ぶ
  after_create_commit :create_initial_character
  # 　uidが存在する場合のみ、その一意性をproviderのスコープ内で確認
  validates :uid, presence: true, uniqueness: { scope: :provider }, if: -> { uid.present? }
  validates :email, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :line_user_id, uniqueness: true, allow_nil: true, length: { maximum: 50 }

  def self.from_omniauth(auth)
    # メール一致 → 同一ユーザー扱い（Google と LINE を統合できる）
    user = User.find_by(email: auth.info.email) if auth.info.email.present?

    # provider + uid で検索
    user ||= User.find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    # 初回ログイン時
    if user.new_record?
      user.name  = auth.info.name
      user.email = auth.info.email.presence || "#{auth.uid}@#{auth.provider}.generated"
      user.password = Devise.friendly_token[0, 20]
    end

    user.save!
    user
  end

  def self.create_unique_string
    SecureRandom.uuid
  end


  private
  def create_initial_character
    egg_kind = CharacterKind.find_by!(asset_key: "egg", stage: 0)
    ch = characters.create!(character_kind: egg_kind, state: :alive, last_activity_at: Time.current)
    update!(active_character: ch)
  end
end
