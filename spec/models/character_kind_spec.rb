require "rails_helper"

RSpec.describe CharacterKind, type: :model do
  # ========== アソシエーション ==========
  describe "associations" do
    describe "characters" do
      it "has_many :characters の関連を持つこと" do
        setup_master_data
        character_kind = create(:character_kind)
        user = create(:user)
        character = Character.create!(
          user: user,
          character_kind: character_kind,
          level: 1,
          exp: 0,
          bond_hp: 50,
          bond_hp_max: 100,
          state: :alive,
          last_activity_at: Time.current
        )
        expect(character_kind.characters).to include(character)
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "name" do
      it "必須であること" do
        character_kind = build(:character_kind, name: nil)
        expect(character_kind).not_to be_valid
        expect(character_kind.errors[:name]).to include("を入力してください")
      end

      it "同じstage内でname重複を許可しないこと" do
        create(:character_kind, name: "グリモンA", stage: :child, asset_key: "green_robo_a")
        duplicate = build(:character_kind, name: "グリモンA", stage: :child, asset_key: "green_robo_a_dup")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("はすでに存在します")
      end

      it "異なるstageであればname重複を許可すること" do
        create(:character_kind, name: "グリモンB", stage: :child, asset_key: "green_robo_b")
        different_stage = build(:character_kind, name: "グリモンB", stage: :adult, asset_key: "green_robo_b_adult")
        expect(different_stage).to be_valid
      end
    end

    describe "stage" do
      it "必須であること" do
        character_kind = build(:character_kind, stage: nil)
        expect(character_kind).not_to be_valid
        expect(character_kind.errors[:stage]).to include("を入力してください")
      end
    end

    describe "asset_key" do
      it "必須であること" do
        character_kind = build(:character_kind, asset_key: nil)
        expect(character_kind).not_to be_valid
        expect(character_kind.errors[:asset_key]).to include("を入力してください")
      end

      it "同じstage内でasset_key重複を許可しないこと" do
        create(:character_kind, name: "キャラA", asset_key: "key_a", stage: :child)
        duplicate = build(:character_kind, name: "キャラB", asset_key: "key_a", stage: :child)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:asset_key]).to include("はすでに存在します")
      end

      it "異なるstageであればasset_key重複を許可すること" do
        create(:character_kind, name: "キャラC", asset_key: "key_c", stage: :child)
        different_stage = build(:character_kind, name: "キャラD", asset_key: "key_c", stage: :adult)
        expect(different_stage).to be_valid
      end
    end
  end

  # ========== Enum ==========
  describe "enums" do
    it "stageがegg, child, adultの値を持つこと" do
      character_kind = create(:character_kind)

      character_kind.update!(stage: :egg)
      expect(character_kind.egg?).to be true

      character_kind.update!(stage: :child)
      expect(character_kind.child?).to be true

      character_kind.update!(stage: :adult)
      expect(character_kind.adult?).to be true
    end

    it "stageの数値マッピングが正しいこと" do
      expect(CharacterKind.stages[:egg]).to eq(0)
      expect(CharacterKind.stages[:child]).to eq(1)
      expect(CharacterKind.stages[:adult]).to eq(2)
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      character_kind = build(:character_kind)
      expect(character_kind).to be_valid
    end

    it "すべての必須属性が揃っていれば保存できること" do
      character_kind = CharacterKind.new(
        name: "テストキャラクター",
        stage: :child,
        asset_key: "test_key"
      )
      expect(character_kind.save).to be true
    end

    it "同じasset_keyとnameでstageを変えたキャラクター種類を作成できること" do
      egg = create(:character_kind, name: "グリモンX", asset_key: "green_robo_x", stage: :egg)
      child = create(:character_kind, name: "グリモンX", asset_key: "green_robo_x", stage: :child)
      adult = create(:character_kind, name: "グリモンX", asset_key: "green_robo_x", stage: :adult)

      expect(egg).to be_persisted
      expect(child).to be_persisted
      expect(adult).to be_persisted
      expect(CharacterKind.where(asset_key: "green_robo_x").count).to eq(3)
    end
  end
end
