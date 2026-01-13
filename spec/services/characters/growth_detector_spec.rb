# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::GrowthDetector, type: :service do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }
  let(:character) { user.active_character }

  describe "#detect" do
    context "卵から孵化するとき" do
      let(:egg_kind) { CharacterKind.find_by!(stage: "egg") }
      let(:child_kind) { CharacterKind.where(stage: "child").first }

      it "hatched: true を返す" do
        character.update!(character_kind: egg_kind, level: 1)

        detector = described_class.new(character)

        # 孵化後の状態をシミュレート
        allow(character).to receive(:reload).and_return(character)
        allow(character).to receive(:level).and_return(2)
        allow(character.character_kind).to receive(:stage).and_return("child")

        result = detector.detect

        expect(result[:hatched]).to be true
        expect(result[:evolved]).to be false
        expect(result[:leveled_up]).to be false
      end
    end

    context "子供から大人に進化するとき" do
      let(:child_kind) { CharacterKind.where(stage: "child").first }
      let(:adult_kind) { CharacterKind.where(stage: "adult").first }

      it "evolved: true を返す" do
        character.update!(character_kind: child_kind, level: 9)

        detector = described_class.new(character)

        # 進化後の状態をシミュレート
        allow(character).to receive(:reload).and_return(character)
        allow(character).to receive(:level).and_return(10)
        allow(character.character_kind).to receive(:stage).and_return("adult")

        result = detector.detect

        expect(result[:evolved]).to be true
        expect(result[:hatched]).to be false
        expect(result[:leveled_up]).to be false
      end
    end

    context "通常のレベルアップ時" do
      let(:child_kind) { CharacterKind.where(stage: "child").first }

      it "leveled_up: true を返す" do
        character.update!(character_kind: child_kind, level: 5)

        detector = described_class.new(character)

        # レベルアップ後の状態をシミュレート
        allow(character).to receive(:reload).and_return(character)
        allow(character).to receive(:level).and_return(6)
        allow(character.character_kind).to receive(:stage).and_return("child")

        result = detector.detect

        expect(result[:leveled_up]).to be true
        expect(result[:hatched]).to be false
        expect(result[:evolved]).to be false
      end
    end

    context "レベルが変化しない時" do
      let(:child_kind) { CharacterKind.where(stage: "child").first }

      it "すべてfalseを返す" do
        character.update!(character_kind: child_kind, level: 5)

        detector = described_class.new(character)

        # レベル変化なし
        allow(character).to receive(:reload).and_return(character)
        allow(character).to receive(:level).and_return(5)
        allow(character.character_kind).to receive(:stage).and_return("child")

        result = detector.detect

        expect(result[:leveled_up]).to be false
        expect(result[:hatched]).to be false
        expect(result[:evolved]).to be false
      end
    end

    context "キャラクターがnilの時" do
      it "すべてfalseを返す" do
        detector = described_class.new(nil)
        result = detector.detect

        expect(result[:hatched]).to be false
        expect(result[:evolved]).to be false
        expect(result[:leveled_up]).to be false
      end
    end
  end
end
