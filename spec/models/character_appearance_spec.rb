require "rails_helper"

RSpec.describe CharacterAppearance, type: :model do
  # ========== アソシエーション ==========
  describe "associations" do
    describe "character_kind" do
      it "belongs_to :character_kind の関連を持つこと" do
        appearance = create(:character_appearance)
        expect(appearance.character_kind).to be_a(CharacterKind)
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "pose" do
      it "必須であること" do
        appearance = build(:character_appearance, pose: nil)
        expect(appearance).not_to be_valid
        expect(appearance.errors[:pose]).to include("を入力してください")
      end

      it "同じcharacter_kind内でpose重複を許可しないこと" do
        character_kind = create(:character_kind)
        create(:character_appearance, character_kind: character_kind, pose: :idle)
        duplicate = build(:character_appearance, character_kind: character_kind, pose: :idle)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:pose]).to include("はすでに存在します")
      end

      it "異なるcharacter_kindであればpose重複を許可すること" do
        character_kind1 = create(:character_kind, asset_key: "pet_a")
        character_kind2 = create(:character_kind, asset_key: "pet_b")
        create(:character_appearance, character_kind: character_kind1, pose: :idle)
        different_kind = build(:character_appearance, character_kind: character_kind2, pose: :idle)
        expect(different_kind).to be_valid
      end
    end

    describe "asset_kind" do
      it "必須であること" do
        appearance = build(:character_appearance, asset_kind: nil)
        expect(appearance).not_to be_valid
        expect(appearance.errors[:asset_kind]).to include("を入力してください")
      end
    end
  end

  # ========== Enum ==========
  describe "enums" do
    describe "pose" do
      it "idle, sleep, happyの値を持つこと" do
        appearance = create(:character_appearance)

        appearance.update!(pose: :idle)
        expect(appearance.idle?).to be true

        appearance.update!(pose: :sleep)
        expect(appearance.sleep?).to be true

        appearance.update!(pose: :happy)
        expect(appearance.happy?).to be true
      end

      it "poseの数値マッピングが正しいこと" do
        expect(CharacterAppearance.poses[:idle]).to eq(0)
        expect(CharacterAppearance.poses[:sleep]).to eq(1)
        expect(CharacterAppearance.poses[:happy]).to eq(2)
      end
    end

    describe "asset_kind" do
      it "webp, pngの値を持つこと" do
        appearance = create(:character_appearance)

        appearance.update!(asset_kind: :webp)
        expect(appearance.webp?).to be true

        appearance.update!(asset_kind: :png)
        expect(appearance.png?).to be true
      end

      it "asset_kindの数値マッピングが正しいこと" do
        expect(CharacterAppearance.asset_kinds[:webp]).to eq(0)
        expect(CharacterAppearance.asset_kinds[:png]).to eq(1)
      end
    end
  end

  # ========== インスタンスメソッド ==========
  describe "#asset_path" do
    it "正しいasset_pathを生成すること (webp, idle)" do
      character_kind = create(:character_kind, asset_key: "green_robo_path1", stage: :child, name: "グリモン1")
      appearance = create(:character_appearance,
        character_kind: character_kind,
        pose: :idle,
        asset_kind: :webp
      )

      expected_path = "characters/green_robo_path1/green_robo_path1_child_idle.webp"
      expect(appearance.asset_path).to eq(expected_path)
    end

    it "正しいasset_pathを生成すること (png, happy)" do
      character_kind = create(:character_kind, asset_key: "blue_dragon_path2", stage: :adult, name: "ドラゴン")
      appearance = create(:character_appearance,
        character_kind: character_kind,
        pose: :happy,
        asset_kind: :png
      )

      expected_path = "characters/blue_dragon_path2/blue_dragon_path2_adult_happy.png"
      expect(appearance.asset_path).to eq(expected_path)
    end

    it "正しいasset_pathを生成すること (egg stage)" do
      character_kind = create(:character_kind, asset_key: "egg_path3", stage: :egg, name: "たまご3")
      appearance = create(:character_appearance,
        character_kind: character_kind,
        pose: :sleep,
        asset_kind: :webp
      )

      expected_path = "characters/egg_path3/egg_path3_egg_sleep.webp"
      expect(appearance.asset_path).to eq(expected_path)
    end

    it "asset_kindの値に応じて拡張子が変わること" do
      character_kind = create(:character_kind, asset_key: "test_pet", stage: :child)

      webp_appearance = create(:character_appearance,
        character_kind: character_kind,
        pose: :idle,
        asset_kind: :webp
      )
      expect(webp_appearance.asset_path).to end_with(".webp")

      # 同じcharacter_kindに異なるposeで作成
      png_appearance = CharacterAppearance.create!(
        character_kind: character_kind,
        pose: :happy,  # 異なるposeを使用
        asset_kind: :png
      )
      expect(png_appearance.asset_path).to end_with(".png")
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      appearance = build(:character_appearance)
      expect(appearance).to be_valid
    end

    it "すべての必須属性が揃っていれば保存できること" do
      character_kind = create(:character_kind)
      appearance = CharacterAppearance.new(
        character_kind: character_kind,
        pose: :idle,
        asset_kind: :webp
      )
      expect(appearance.save).to be true
    end

    it "同じcharacter_kindに対して複数の異なるposeを作成できること" do
      character_kind = create(:character_kind)
      idle = create(:character_appearance, character_kind: character_kind, pose: :idle)
      sleep = create(:character_appearance, character_kind: character_kind, pose: :sleep)
      happy = create(:character_appearance, character_kind: character_kind, pose: :happy)

      expect(idle).to be_persisted
      expect(sleep).to be_persisted
      expect(happy).to be_persisted
      expect(CharacterAppearance.where(character_kind: character_kind).count).to eq(3)
    end
  end
end
