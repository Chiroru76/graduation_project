require "rails_helper"

RSpec.describe UserTitle, type: :model do
  # ========== アソシエーション ==========
  describe "associations" do
    describe "user" do
      it "belongs_to :user の関連を持つこと" do
        user_title = create(:user_title)
        expect(user_title.user).to be_a(User)
      end
    end

    describe "title" do
      it "belongs_to :title の関連を持つこと" do
        user_title = create(:user_title)
        expect(user_title.title).to be_a(Title)
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "unlocked_at" do
      it "必須であること" do
        user_title = build(:user_title, unlocked_at: nil)
        expect(user_title).not_to be_valid
        expect(user_title.errors[:unlocked_at]).to include("を入力してください")
      end

      it "有効な日時が設定できること" do
        user_title = build(:user_title, unlocked_at: Time.current)
        expect(user_title).to be_valid
      end
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      user_title = build(:user_title)
      expect(user_title).to be_valid
    end

    it "すべての必須属性が揃っていれば保存できること" do
      user = create(:user)
      title = create(:title)
      user_title = UserTitle.new(
        user: user,
        title: title,
        unlocked_at: Time.current
      )
      expect(user_title.save).to be true
    end

    it "同じユーザーが異なる称号をアンロックできること" do
      user = create(:user)
      title1 = create(:title, key: "title_1")
      title2 = create(:title, key: "title_2")

      first_unlock = UserTitle.create!(
        user: user,
        title: title1,
        unlocked_at: Time.current
      )

      second_unlock = UserTitle.create!(
        user: user,
        title: title2,
        unlocked_at: Time.current
      )

      expect(first_unlock).to be_persisted
      expect(second_unlock).to be_persisted
      expect(user.user_titles.count).to eq(2)
    end

    it "同じユーザーが同じ称号を複数回アンロックできないこと" do
      user = create(:user)
      title = create(:title)

      UserTitle.create!(
        user: user,
        title: title,
        unlocked_at: 1.day.ago
      )

      expect {
        UserTitle.create!(
          user: user,
          title: title,
          unlocked_at: Time.current
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "異なるユーザーが同じ称号をアンロックできること" do
      user1 = create(:user)
      user2 = create(:user)
      title = create(:title)

      first_unlock = UserTitle.create!(
        user: user1,
        title: title,
        unlocked_at: Time.current
      )

      second_unlock = UserTitle.create!(
        user: user2,
        title: title,
        unlocked_at: Time.current
      )

      expect(first_unlock).to be_persisted
      expect(second_unlock).to be_persisted
    end
  end
end
