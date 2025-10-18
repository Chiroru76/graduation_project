# create_table "characters", force: :cascade do |t|
#   t.bigint "user_id", null: false
#   t.bigint "character_kind_id", null: false
#   t.integer "level", default: 1, null: false
#   t.integer "exp", default: 0, null: false
#   t.integer "bond_hp", default: 0, null: false
#   t.integer "bond_hp_max", default: 100, null: false
#   t.integer "state", default: 0, null: false
#   t.datetime "last_activity_at"
#   t.datetime "dead_at"
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
#   t.index ["character_kind_id"], name: "index_characters_on_character_kind_id"
#   t.index ["user_id"], name: "index_characters_on_user_id"
# end

# create_table "character_kinds", force: :cascade do |t|
#   t.string "name", null: false
#   t.integer "stage", default: 0, null: false
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
#   t.string "asset_key", null: false
#   t.index ["asset_key", "stage"], name: "index_character_kinds_on_asset_key_and_stage", unique: true
#   t.index ["name", "stage"], name: "index_character_kinds_on_name_and_stage", unique: true
# end
class Character < ApplicationRecord
  belongs_to :user
  belongs_to :character_kind

  enum :state, { alive: 0, dead: 1 }

  validates :level, numericality: { greater_than_or_equal_to: 1 }
  validates :exp, :bond_hp, :bond_hp_max, numericality: { greater_than_or_equal_to: 0 }
  validates :bond_hp, numericality: { less_than_or_equal_to: :bond_hp_max }

  # レベルアップに必要な経験値の計算式
  def self.threshold_exp_for_next_level(level)
    return 0 if level < 1
    # レベルが上がるごとに値が1.2倍される
    (1..level).sum { |n| (100 * 1.2**(n - 1)).to_i }
  end
  # 現在のレベルに到達するのに必要だった累計経験値
  def exp_floor
    self.class.threshold_exp_for_next_level(level - 1)
  end

  # 次のレベルに上がるために必要な累計経験値
  def exp_ceiling
    self.class.threshold_exp_for_next_level(level)
  end

  # 現在のレベルでどれだけ経験値を獲得しているか
  def current_level_exp
    exp - exp_floor
  end

  # 次のレベルに上がるために必要な経験値
  def exp_needed
    exp_ceiling - exp
  end

  # 経験値ゲージの進捗率（％）
  def exp_progress_percentage
    ((current_level_exp.to_f/(exp_ceiling - exp_floor)) * 100).round
  end

  # えさやりメソッド
  def feed!(user)
    return if bond_hp >= bond_hp_max
    return if user.food_count <= 5
    # 1回のえさやりで増加するきずなHP
    gain = 10
    # エサの消費・きずなHP増加をトランザクションでまとめて実行
    transaction do
      self.last_activity_at = Time.current # キャラクターの最終活動日を更新
      user.decrement!(:food_count, 5)
      increment!(:bond_hp, gain)
      if bond_hp > bond_hp_max
        update!(bond_hp: bond_hp_max)
      end
    end
    true
  end

  # きずなゲージの進捗率（％）
  def bond_hp_ratio
    ((bond_hp.to_f / bond_hp_max.to_f) * 100).round
  end

  # 経験値加算の処理の入り口
  def gain_exp!(amount)
    return if amount <= 0
    with_lock do
      self.exp += amount
      check_level_up
      self.last_activity_at = Time.current # キャラクターの最終活動日を更新
      save!
    end
  end

  # レベルアップ判定と処理
  def check_level_up
    while exp >= exp_ceiling
      self.level += 1

      # 初めてのレベルアップ時にstage: :egg → stage: :childのキャラに変化
      if level == 2 && character_kind.egg?
        # CharacterKindからstage: :childであるキャラを探してランダムで選択
        self.character_kind = CharacterKind.where(stage: :child).sample
      end
    end
    evolve_to_adult!
  end

  def evolve_to_adult!
    return unless level >= 10 && character_kind.child?
    adult_kind = CharacterKind.find_by(asset_key: character_kind.asset_key, stage: :adult)
    update!(character_kind: adult_kind)
  end

  def die!
    update!(state: :dead, dead_at: Time.current)
  end
end
