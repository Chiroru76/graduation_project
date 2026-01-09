require "rails_helper"

RSpec.describe Title, type: :model do
  # ========== アソシエーション ==========
  describe "associations" do
    describe "user_titles" do
      it "has_many :user_titles の関連を持つこと" do
        title = create(:title)
        user_title = UserTitle.create!(
          title: title,
          user: create(:user),
          unlocked_at: Time.current
        )
        expect(title.user_titles).to include(user_title)
      end

      it "タイトルが削除されるとuser_titlesも削除されること" do
        title = create(:title)
        UserTitle.create!(
          title: title,
          user: create(:user),
          unlocked_at: Time.current
        )

        expect { title.destroy }.to change { UserTitle.count }.by(-1)
      end
    end

    describe "users" do
      it "has_many :users, through: :user_titles の関連を持つこと" do
        title = create(:title)
        user = create(:user)
        UserTitle.create!(
          title: title,
          user: user,
          unlocked_at: Time.current
        )

        expect(title.users).to include(user)
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "key" do
      it "必須であること" do
        title = build(:title, key: nil)
        expect(title).not_to be_valid
        expect(title.errors[:key]).to include("を入力してください")
      end

      it "一意である必要があること" do
        create(:title, key: "unique_key")
        duplicate = build(:title, key: "unique_key")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:key]).to include("はすでに存在します")
      end
    end

    describe "name" do
      it "必須であること" do
        title = build(:title, name: nil)
        expect(title).not_to be_valid
        expect(title.errors[:name]).to include("を入力してください")
      end
    end

    describe "rule_type" do
      it "必須であること" do
        title = build(:title, rule_type: nil)
        expect(title).not_to be_valid
        expect(title.errors[:rule_type]).to include("を入力してください")
      end
    end

    describe "threshold" do
      it "必須であること" do
        title = build(:title, threshold: nil)
        expect(title).not_to be_valid
        expect(title.errors[:threshold]).to include("を入力してください")
      end

      it "0より大きい値である必要があること" do
        title = build(:title, threshold: 0)
        expect(title).not_to be_valid
        expect(title.errors[:threshold]).to include("は0より大きい値にしてください")
      end

      it "負の値を許可しないこと" do
        title = build(:title, threshold: -1)
        expect(title).not_to be_valid
        expect(title.errors[:threshold]).to include("は0より大きい値にしてください")
      end

      it "正の値は有効であること" do
        title = build(:title, threshold: 10)
        expect(title).to be_valid
      end
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      title = build(:title)
      expect(title).to be_valid
    end

    it "すべての必須属性が揃っていれば保存できること" do
      title = build(:title,
                    key: "test_key",
                    name: "テスト称号",
                    rule_type: "todo_completion",
                    threshold: 10)
      expect(title.save).to be true
    end
  end
end
