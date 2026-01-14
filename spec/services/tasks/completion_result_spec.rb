# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::CompletionResult do
  let(:user) { create(:user) }
  let(:task) { create(:task, :todo, user: user, status: :done) }

  let(:growth_result) do
    { hatched: false, evolved: true, leveled_up: false }
  end

  let(:pet_response) do
    {
      comment: "レベルアップしたよ！",
      appearance: instance_double(CharacterAppearance)
    }
  end

  let(:unlocked_titles) { [create(:title)] }

  subject(:result) do
    described_class.new(
      task: task,
      notice: "TODOを完了しました",
      growth_result: growth_result,
      pet_response: pet_response,
      unlocked_titles: unlocked_titles
    )
  end

  describe "#initialize" do
    it "すべての属性を正しく保持する" do
      expect(result.task).to eq task
      expect(result.notice).to eq "TODOを完了しました"
      expect(result.growth_result).to eq growth_result
      expect(result.pet_response).to eq pet_response
      expect(result.unlocked_titles).to eq unlocked_titles
    end
  end

  describe "#hatched?" do
    context "孵化した場合" do
      let(:growth_result) { { hatched: true, evolved: false, leveled_up: false } }

      it "trueを返す" do
        expect(result.hatched?).to be true
      end
    end

    context "孵化していない場合" do
      let(:growth_result) { { hatched: false, evolved: false, leveled_up: false } }

      it "falseを返す" do
        expect(result.hatched?).to be false
      end
    end
  end

  describe "#evolved?" do
    context "進化した場合" do
      let(:growth_result) { { hatched: false, evolved: true, leveled_up: false } }

      it "trueを返す" do
        expect(result.evolved?).to be true
      end
    end

    context "進化していない場合" do
      let(:growth_result) { { hatched: false, evolved: false, leveled_up: false } }

      it "falseを返す" do
        expect(result.evolved?).to be false
      end
    end
  end

  describe "#leveled_up?" do
    context "レベルアップした場合" do
      let(:growth_result) { { hatched: false, evolved: false, leveled_up: true } }

      it "trueを返す" do
        expect(result.leveled_up?).to be true
      end
    end

    context "レベルアップしていない場合" do
      let(:growth_result) { { hatched: false, evolved: false, leveled_up: false } }

      it "falseを返す" do
        expect(result.leveled_up?).to be false
      end
    end
  end

  describe "#pet_comment" do
    it "ペットレスポンスのコメントを返す" do
      expect(result.pet_comment).to eq "レベルアップしたよ！"
    end

    context "コメントがない場合" do
      let(:pet_response) { { comment: nil, appearance: nil } }

      it "nilを返す" do
        expect(result.pet_comment).to be_nil
      end
    end
  end

  describe "#appearance" do
    it "ペットのアピアランスを返す" do
      expect(result.appearance).to eq pet_response[:appearance]
    end

    context "アピアランスがない場合" do
      let(:pet_response) { { comment: nil, appearance: nil } }

      it "nilを返す" do
        expect(result.appearance).to be_nil
      end
    end
  end

  describe "#completed?" do
    context "タスクが完了状態の場合" do
      let(:task) { create(:task, :todo, user: user, status: :done) }

      it "trueを返す" do
        expect(result.completed?).to be true
      end
    end

    context "タスクが未完了状態の場合" do
      let(:task) { create(:task, :todo, user: user, status: :open) }

      it "falseを返す" do
        expect(result.completed?).to be false
      end
    end
  end
end
