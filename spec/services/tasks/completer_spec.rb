# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::Completer, type: :service do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }
  let(:character) { user.active_character }
  let(:task) { create(:task, :todo, user: user, state: :open) }

  describe "#call" do
    context "TODOを完了するとき" do
      it "タスクが完了状態になる" do
        completer = described_class.new(task, user)
        result = completer.call

        expect(task.reload).to be_done
        expect(result).to be_a(Tasks::CompletionResult)
        expect(result.notice).to eq "TODOを完了しました"
      end

      it "CompletionResultを返す" do
        completer = described_class.new(task, user)
        result = completer.call

        expect(result).to be_a(Tasks::CompletionResult)
        expect(result.task).to eq task.reload
        expect(result.notice).to eq "TODOを完了しました"
      end
    end

    context "習慣（checkbox型）を完了するとき" do
      let(:habit) { create(:task, :habit, user: user, state: :open, tracking_mode: :checkbox) }

      it "タスクが完了状態になる" do
        completer = described_class.new(habit, user)
        result = completer.call

        expect(habit.reload).to be_done
        expect(result.notice).to eq "習慣を完了しました"
        expect(result).to be_a(Tasks::CompletionResult)
      end
    end

    context "習慣を未完了に戻す時" do
      let(:habit) { create(:task, :habit, user: user, state: :done) }

      it "未完了状態になる" do
        completer = described_class.new(habit, user)
        result = completer.call

        expect(habit.reload).to be_open
        expect(result.notice).to eq "習慣を未完了に戻しました"
        expect(result.completed?).to be false
      end
    end

    context "数量ログ型の習慣の場合" do
      let(:log_habit) { create(:task, :habit, user: user, tracking_mode: :log) }

      it "エラーメッセージを返す" do
        completer = described_class.new(log_habit, user)
        result = completer.call

        expect(result.notice).to include "数量ログで記録してください"
        expect(result.hatched?).to be false
        expect(result.evolved?).to be false
      end
    end

    context "タスク完了時にペットが進化する場合" do
      it "進化フラグがtrueになる" do
        child_kind = CharacterKind.where(stage: "child").first
        adult_kind = CharacterKind.where(stage: "adult").first
        character.update!(character_kind: child_kind, level: 9, exp: 900)

        task = create(:task, :todo, user: user)
        allow_any_instance_of(Task).to receive(:complete!).and_wrap_original do |method, **args|
          result = method.call
          character.update!(character_kind: adult_kind, level: 10, exp: 0)
          result
        end

        completer = described_class.new(task, user)
        result = completer.call

        expect(result.evolved?).to be true
        expect(result.hatched?).to be false
        expect(result.leveled_up?).to be false
      end
    end

    context "数量ログ型の習慣のとき" do
      let(:log_habit) { create(:task, :habit, user: user, tracking_mode: :log) }

      it "エラーメッセージを返す" do
        completer = described_class.new(log_habit, user)
        result = completer.call

        expect(result.notice).to eq "この習慣は数量ログで記録してください"
        expect(result.evolved?).to be false
        expect(result.hatched?).to be false
      end
    end

    context "キャラクターが存在しない場合" do
      let(:user_without_character) { create(:user) }

      before do
        user_without_character.characters.destroy_all
      end

      it "エラーなく処理される" do
        task = create(:task, :todo, user: user)
        completer = described_class.new(task, user)

        expect { completer.call }.not_to raise_error
      end
    end
  end
end
