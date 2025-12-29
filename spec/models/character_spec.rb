require "rails_helper"

RSpec.describe Character, type: :model do
  # マスターデータのセットアップ
  before(:all) do
    # たまご
    @egg_kind = CharacterKind.find_or_create_by!(asset_key: "egg", stage: :egg) do |k|
      k.name = "たまご"
    end
    # 子ども
    @child_kind = CharacterKind.find_or_create_by!(asset_key: "green_robo", stage: :child) do |k|
      k.name = "グリモン"
    end
    # 大人
    @adult_kind = CharacterKind.find_or_create_by!(asset_key: "green_robo", stage: :adult) do |k|
      k.name = "グリモン"
    end
  end

  # ========== アソシエーション ==========
  describe "associations" do
    describe "user" do
      it "belongs_to :user の関連を持つこと" do
        character = create(:character)
        expect(character.user).to be_a(User)
      end
    end

    describe "character_kind" do
      it "belongs_to :character_kind の関連を持つこと" do
        character = create(:character)
        expect(character.character_kind).to be_a(CharacterKind)
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "level" do
      it "1以上である必要があること" do
        character = build(:character, level: 0)
        expect(character).not_to be_valid
        expect(character.errors[:level]).to include("は1以上の値にしてください")
      end

      it "1を許可すること" do
        character = build(:character, level: 1)
        expect(character).to be_valid
      end

      it "正の値を許可すること" do
        character = build(:character, level: 10)
        expect(character).to be_valid
      end
    end

    describe "exp" do
      it "0以上である必要があること" do
        character = build(:character, exp: -1)
        expect(character).not_to be_valid
        expect(character.errors[:exp]).to include("は0以上の値にしてください")
      end

      it "0を許可すること" do
        character = build(:character, exp: 0)
        expect(character).to be_valid
      end
    end

    describe "bond_hp" do
      it "0以上である必要があること" do
        character = build(:character, bond_hp: -1)
        expect(character).not_to be_valid
        expect(character.errors[:bond_hp]).to include("は0以上の値にしてください")
      end

      it "bond_hp_max以下である必要があること" do
        character = build(:character, bond_hp: 150, bond_hp_max: 100)
        expect(character).not_to be_valid
        expect(character.errors[:bond_hp]).to include("は100以下の値にしてください")
      end

      it "bond_hp_maxと同じ値を許可すること" do
        character = build(:character, bond_hp: 100, bond_hp_max: 100)
        expect(character).to be_valid
      end
    end

    describe "bond_hp_max" do
      it "0以上である必要があること" do
        character = build(:character, bond_hp_max: -1)
        expect(character).not_to be_valid
        expect(character.errors[:bond_hp_max]).to include("は0以上の値にしてください")
      end
    end
  end

  # ========== Enum ==========
  describe "enums" do
    describe "state" do
      it "alive, deadの値を持つこと" do
        character = create(:character)

        character.update!(state: :alive)
        expect(character.alive?).to be true

        character.update!(state: :dead)
        expect(character.dead?).to be true
      end

      it "stateの数値マッピングが正しいこと" do
        expect(Character.states[:alive]).to eq(0)
        expect(Character.states[:dead]).to eq(1)
      end
    end
  end

  # ========== クラスメソッド ==========
  describe ".threshold_exp_for_next_level" do
    it "level 0以下の場合は0を返すこと" do
      expect(Character.threshold_exp_for_next_level(0)).to eq(0)
      expect(Character.threshold_exp_for_next_level(-1)).to eq(0)
    end

    it "level 1で100を返すこと" do
      expect(Character.threshold_exp_for_next_level(1)).to eq(100)
    end

    it "level 2で220を返すこと (100 + 120)" do
      expect(Character.threshold_exp_for_next_level(2)).to eq(220)
    end

    it "level 3で364を返すこと (100 + 120 + 144)" do
      expect(Character.threshold_exp_for_next_level(3)).to eq(364)
    end

    it "levelが上がるほど必要経験値が増加すること" do
      level_1_threshold = Character.threshold_exp_for_next_level(1)
      level_2_threshold = Character.threshold_exp_for_next_level(2)
      level_3_threshold = Character.threshold_exp_for_next_level(3)

      expect(level_2_threshold).to be > level_1_threshold
      expect(level_3_threshold).to be > level_2_threshold
    end
  end

  # ========== インスタンスメソッド ==========
  describe "#exp_floor" do
    it "現在のレベルに到達するのに必要だった累計経験値を返すこと" do
      character = create(:character, level: 2, exp: 200)
      expect(character.exp_floor).to eq(100) # level 1の閾値
    end

    it "level 1の場合は0を返すこと" do
      character = create(:character, level: 1, exp: 50)
      expect(character.exp_floor).to eq(0)
    end
  end

  describe "#exp_ceiling" do
    it "次のレベルに上がるために必要な累計経験値を返すこと" do
      character = create(:character, level: 1, exp: 50)
      expect(character.exp_ceiling).to eq(100)
    end

    it "level 2の場合は220を返すこと" do
      character = create(:character, level: 2, exp: 150)
      expect(character.exp_ceiling).to eq(220)
    end
  end

  describe "#current_level_exp" do
    it "現在のレベルでどれだけ経験値を獲得しているかを返すこと" do
      character = create(:character, level: 1, exp: 50)
      expect(character.current_level_exp).to eq(50) # 50 - 0
    end

    it "level 2の途中の場合、前レベルからの差分を返すこと" do
      character = create(:character, level: 2, exp: 150)
      expect(character.current_level_exp).to eq(50) # 150 - 100
    end
  end

  describe "#exp_needed" do
    it "次のレベルに上がるために必要な経験値を返すこと" do
      character = create(:character, level: 1, exp: 50)
      expect(character.exp_needed).to eq(50) # 100 - 50
    end

    it "レベル上限に近い場合も正しく計算すること" do
      character = create(:character, level: 2, exp: 200)
      expect(character.exp_needed).to eq(20) # 220 - 200
    end
  end

  describe "#exp_progress_percentage" do
    it "経験値ゲージの進捗率（％）を返すこと" do
      character = create(:character, level: 1, exp: 50)
      # current_level_exp = 50, (exp_ceiling - exp_floor) = 100
      expect(character.exp_progress_percentage).to eq(50)
    end

    it "進捗率が0%の場合" do
      character = create(:character, level: 1, exp: 0)
      expect(character.exp_progress_percentage).to eq(0)
    end

    it "進捗率がほぼ100%の場合" do
      character = create(:character, level: 1, exp: 99)
      expect(character.exp_progress_percentage).to eq(99)
    end
  end

  describe "#bond_hp_ratio" do
    it "きずなゲージの進捗率（％）を返すこと" do
      character = create(:character, bond_hp: 50, bond_hp_max: 100)
      expect(character.bond_hp_ratio).to eq(50)
    end

    it "きずなゲージが0%の場合" do
      character = create(:character, bond_hp: 0, bond_hp_max: 100)
      expect(character.bond_hp_ratio).to eq(0)
    end

    it "きずなゲージが100%の場合" do
      character = create(:character, bond_hp: 100, bond_hp_max: 100)
      expect(character.bond_hp_ratio).to eq(100)
    end
  end

  describe "#feed!" do
    let(:user) { create(:user) }

    it "えさやりでbond_hpが10増加すること" do
      user.update!(food_count: 5)
      character = create(:character, user: user, bond_hp: 30, bond_hp_max: 100)

      expect {
        character.feed!(user)
      }.to change { character.reload.bond_hp }.by(10)

      expect(user.reload.food_count).to eq(4)
    end

    it "bond_hpがbond_hp_maxを超えないこと" do
      user.update!(food_count: 5)
      character = create(:character, user: user, bond_hp: 95, bond_hp_max: 100)

      character.feed!(user)

      expect(character.reload.bond_hp).to eq(100)
    end

    it "bond_hpがすでにbond_hp_maxの場合は何もしないこと" do
      user.update!(food_count: 5)
      character = create(:character, user: user, bond_hp: 100, bond_hp_max: 100)

      expect {
        character.feed!(user)
      }.not_to change { character.reload.bond_hp }

      expect(user.reload.food_count).to eq(5) # 食べ物は消費されない
    end

    it "ユーザーの食べ物が0の場合は何もしないこと" do
      user.update!(food_count: 0)
      character = create(:character, user: user, bond_hp: 50, bond_hp_max: 100)

      expect {
        character.feed!(user)
      }.not_to change { character.reload.bond_hp }
    end

    it "最終活動時刻が記録されること" do
      user.update!(food_count: 5)
      character = create(:character, user: user, bond_hp: 50, bond_hp_max: 100)

      character.feed!(user)

      # last_activity_atが設定されていることを確認
      expect(character.reload.last_activity_at).to be_present
    end
  end

  describe "#gain_exp!" do
    it "経験値が加算されること" do
      character = create(:character, level: 1, exp: 50)

      expect {
        character.gain_exp!(30)
      }.to change { character.reload.exp }.by(30)
    end

    it "0以下の値の場合は何もしないこと" do
      character = create(:character, level: 1, exp: 50)

      expect {
        character.gain_exp!(0)
      }.not_to change { character.reload.exp }

      expect {
        character.gain_exp!(-10)
      }.not_to change { character.reload.exp }
    end

    it "last_activity_atが更新されること" do
      old_time = 1.day.ago
      character = create(:character, level: 1, exp: 50, last_activity_at: old_time)

      character.gain_exp!(20)
      expect(character.reload.last_activity_at).to be > old_time
    end

    it "経験値がexp_ceilingを超えるとレベルアップすること" do
      character = create(:character, level: 1, exp: 90)

      expect {
        character.gain_exp!(20) # 合計110、threshold=100を超える
      }.to change { character.reload.level }.by(1)
    end

    it "複数レベルアップすること" do
      character = create(:character, level: 1, exp: 0)

      # level 1→2の閾値=100, level 2→3の閾値=220
      # 300の経験値を付与すると level 3になる
      expect {
        character.gain_exp!(300)
      }.to change { character.reload.level }.from(1).to(3)
    end
  end

  describe "#decrease_exp!" do
    it "経験値が減算されること" do
      character = create(:character, level: 2, exp: 150)

      expect {
        character.decrease_exp!(30)
      }.to change { character.reload.exp }.by(-30)
    end

    it "経験値が0未満にならないこと" do
      character = create(:character, level: 1, exp: 50)

      character.decrease_exp!(100)

      expect(character.reload.exp).to eq(0)
    end

    it "0以下の値の場合は何もしないこと" do
      character = create(:character, level: 1, exp: 50)

      expect {
        character.decrease_exp!(0)
      }.not_to change { character.reload.exp }

      expect {
        character.decrease_exp!(-10)
      }.not_to change { character.reload.exp }
    end
  end

  describe "#check_level_up" do
    it "たまご(egg)がレベル2になると子ども(child)に進化すること" do
      character = create(:character, character_kind: @egg_kind, level: 1, exp: 99)

      character.exp = 110
      character.check_level_up
      character.save!

      expect(character.reload.level).to eq(2)
      expect(character.character_kind.stage).to eq("child")
    end

    it "経験値が足りない場合はレベルアップしないこと" do
      character = create(:character, level: 1, exp: 50)

      character.check_level_up

      expect(character.level).to eq(1)
    end

    it "複数回レベルアップが発生すること" do
      character = create(:character, character_kind: @child_kind, level: 1, exp: 0)

      character.exp = 300
      character.check_level_up

      expect(character.level).to eq(3)
    end
  end

  describe "#evolve_to_adult!" do
    it "子ども(child)がレベル10で大人(adult)に進化すること" do
      character = create(:character, character_kind: @child_kind, level: 10, exp: 1000)

      character.evolve_to_adult!

      expect(character.reload.character_kind.stage).to eq("adult")
      expect(character.character_kind.asset_key).to eq(@child_kind.asset_key)
    end

    it "level 9では進化しないこと" do
      character = create(:character, character_kind: @child_kind, level: 9, exp: 500)

      character.evolve_to_adult!

      expect(character.reload.character_kind.stage).to eq("child")
    end

    it "たまご(egg)では進化しないこと" do
      character = create(:character, character_kind: @egg_kind, level: 10, exp: 1000)

      character.evolve_to_adult!

      expect(character.reload.character_kind.stage).to eq("egg")
    end

    it "すでに大人(adult)の場合は何もしないこと" do
      character = create(:character, character_kind: @adult_kind, level: 15, exp: 2000)
      original_kind_id = character.character_kind_id

      character.evolve_to_adult!

      expect(character.reload.character_kind_id).to eq(original_kind_id)
    end
  end

  describe "#die!" do
    it "stateがdeadになること" do
      character = create(:character, state: :alive)

      expect {
        character.die!
      }.to change { character.reload.state }.from("alive").to("dead")
    end

    it "dead_atが設定されること" do
      character = create(:character, state: :alive, dead_at: nil)

      character.die!
      expect(character.reload.dead_at).to be_present
      expect(character.dead_at).to be_within(1.second).of(Time.current)
    end
  end

  # ========== 統合テスト ==========
  describe "integration tests" do
    it "たまごからの育成シナリオ: たまご→子ども→大人" do
      user = create(:user)
      character = create(:character, user: user, character_kind: @egg_kind, level: 1, exp: 0)

      # レベル2で子どもに進化
      character.gain_exp!(100)
      expect(character.reload.level).to eq(2)
      expect(character.character_kind.stage).to eq("child")

      # さらに経験値を積んでレベル10に
      # level 10に到達するには累計で threshold_exp_for_next_level(10) が必要
      # 現在の経験値は100なので、足りない分を追加
      needed_total_exp = Character.threshold_exp_for_next_level(10)
      current_exp = character.exp
      needed_exp = needed_total_exp - current_exp

      character.gain_exp!(needed_exp)

      character.reload
      expect(character.level).to be >= 10
      expect(character.character_kind.stage).to eq("adult")
    end

    it "えさやりと経験値獲得を組み合わせたシナリオ" do
      user = create(:user)
      user.update!(food_count: 10)

      character = create(:character, user: user, bond_hp: 0, bond_hp_max: 100, level: 1, exp: 0)

      # えさやりでbond_hpを増やす
      3.times { character.feed!(user) }
      expect(character.reload.bond_hp).to eq(30)
      expect(user.reload.food_count).to eq(7)

      # 経験値を獲得してレベルアップ
      character.gain_exp!(100)
      expect(character.reload.level).to eq(2)
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      character = build(:character)
      expect(character).to be_valid
    end
  end
end
