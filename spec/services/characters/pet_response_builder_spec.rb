# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::PetResponseBuilder, type: :service do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }
  let(:character) { user.active_character }
  let(:pet_comment_generator) { instance_double(PetComments::Generator) }

  describe "#generate_comment" do
    context "進化時" do
      let(:evolution_result) { { hatched: false, evolved: true, leveled_up: false } }
      let(:event_context) { { task_completed: true, task_title: "勉強", difficulty: "medium" } }

      it "nilを返す（専用モーダルがあるため）" do
        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        expect(builder.generate_comment).to be_nil
      end
    end

    context "孵化時" do
      let(:evolution_result) { { hatched: true, evolved: false, leveled_up: false } }
      let(:event_context) { { task_completed: true, task_title: "勉強", difficulty: "medium" } }

      it "nilを返す（専用モーダルがあるため）" do
        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        expect(builder.generate_comment).to be_nil
      end
    end

    context "レベルアップ時" do
      let(:evolution_result) { { hatched: false, evolved: false, leveled_up: true } }
      let(:event_context) { { task_completed: true } }

      it ":level_upイベントでコメントを生成する" do
        allow(PetComments::Generator).to receive(:for).and_return("レベルアップしたよ！")

        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        result = builder.generate_comment

        expect(result).to eq("レベルアップしたよ！")
        expect(PetComments::Generator).to have_received(:for).with(
          :level_up,
          user: user,
          context: event_context
        )
      end
    end

    context "タスク完了時（レベルアップなし）" do
      let(:evolution_result) { { hatched: false, evolved: false, leveled_up: false } }
      let(:event_context) { { task_completed: true, task_title: "掃除", difficulty: "easy" } }

      it ":task_completedイベントでコメントを生成する" do
        allow(PetComments::Generator).to receive(:for).and_return("頑張ったね！")

        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        result = builder.generate_comment

        expect(result).to eq("頑張ったね！")
        expect(PetComments::Generator).to have_received(:for).with(
          :task_completed,
          user: user,
          context: event_context
        )
      end
    end

    context "タスク未完了でレベルアップもなし" do
      let(:evolution_result) { { hatched: false, evolved: false, leveled_up: false } }
      let(:event_context) { { task_completed: false } }

      it "nilを返す（イベントが発生していないため）" do
        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        expect(builder.generate_comment).to be_nil
      end
    end

    context "event_contextが空の場合" do
      let(:evolution_result) { { hatched: false, evolved: false, leveled_up: false } }
      let(:event_context) { {} }

      it "nilを返す" do
        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        expect(builder.generate_comment).to be_nil
      end
    end

    context "PetComments::Generatorがnilを返す場合" do
      let(:evolution_result) { { hatched: false, evolved: false, leveled_up: true } }
      let(:event_context) { { task_completed: true } }

      it "nilを返す" do
        allow(PetComments::Generator).to receive(:for).and_return(nil)

        builder = described_class.new(
          character: character,
          evolution_result: evolution_result,
          event_context: event_context
        )

        expect(builder.generate_comment).to be_nil
      end
    end
  end
end
