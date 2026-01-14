# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::AmountLogger, type: :service do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }
  let(:character) { user.active_character }
  let(:log_habit) { create(:task, :habit, user: user, tracking_mode: :log, target_unit: :minutes) }

  describe "#call" do
    context "数量ログを記録するとき" do
      it "タスクに数量が記録される" do
        logger = described_class.new(log_habit, user, amount: 30, unit: "minutes")
        result = logger.call

        expect(result).to be_a(Tasks::CompletionResult)
        expect(result.notice).to eq "記録しました"
        expect(log_habit.task_events.count).to eq 1
        expect(log_habit.task_events.last.amount).to eq 30
      end

      it "CompletionResultを返す" do
        logger = described_class.new(log_habit, user, amount: 30, unit: "minutes")
        result = logger.call

        expect(result).to be_a(Tasks::CompletionResult)
        expect(result.task).to eq log_habit.reload
        expect(result.notice).to eq "記録しました"
      end
    end

    context "数量ログ型ではないタスクの場合" do
      let(:todo) { create(:task, :todo, user: user) }

      it "エラーメッセージを返す" do
        logger = described_class.new(todo, user, amount: 30, unit: "minutes")
        result = logger.call

        expect(result.notice).to eq "この習慣は数量ログ型ではありません"
        expect(result.evolved?).to be false
        expect(result.hatched?).to be false
      end
    end

    context "数量ログ記録時にペットが進化する場合" do
      it "進化フラグがtrueになる" do
        child_kind = CharacterKind.where(stage: "child").first
        adult_kind = CharacterKind.where(stage: "adult").first
        character.update!(character_kind: child_kind, level: 9, exp: 900)

        # log!実行後に進化する状態をシミュレート
        allow_any_instance_of(Task).to receive(:log!).and_wrap_original do |method, **args|
          result = method.call(**args)
          character.update!(character_kind: adult_kind, level: 10, exp: 0)
          result
        end

        logger = described_class.new(log_habit, user, amount: 30, unit: "minutes")
        result = logger.call

        expect(result.evolved?).to be true
        expect(result.hatched?).to be false
        expect(result.leveled_up?).to be false
      end
    end

    context "数量ログ記録時にペットが孵化する場合" do
      it "孵化フラグがtrueになる" do
        egg_kind = CharacterKind.where(stage: "egg").first
        child_kind = CharacterKind.where(stage: "child").first
        character.update!(character_kind: egg_kind, level: 1, exp: 90)

        # log!実行後に孵化する状態をシミュレート
        allow_any_instance_of(Task).to receive(:log!).and_wrap_original do |method, **args|
          result = method.call(**args)
          character.update!(character_kind: child_kind, level: 2, exp: 0)
          result
        end

        logger = described_class.new(log_habit, user, amount: 30, unit: "minutes")
        result = logger.call

        expect(result.hatched?).to be true
        expect(result.evolved?).to be false
        expect(result.leveled_up?).to be false
      end
    end

    context "数量ログ記録時にレベルアップする場合" do
      it "レベルアップフラグがtrueになる" do
        child_kind = CharacterKind.where(stage: "child").first
        character.update!(character_kind: child_kind, level: 3, exp: 290)

        # log!実行後にレベルアップする状態をシミュレート
        allow_any_instance_of(Task).to receive(:log!).and_wrap_original do |method, **args|
          result = method.call(**args)
          character.update!(level: 4, exp: 0)
          result
        end

        logger = described_class.new(log_habit, user, amount: 30, unit: "minutes")
        result = logger.call

        expect(result.leveled_up?).to be true
        expect(result.evolved?).to be false
        expect(result.hatched?).to be false
      end
    end

    context "キャラクターが存在しない場合" do
      let(:user_without_character) { create(:user) }

      before do
        allow(user_without_character).to receive(:active_character).and_return(nil)
      end

      it "エラーなく処理される" do
        task = create(:task, :habit, user: user_without_character, tracking_mode: :log)
        logger = described_class.new(task, user_without_character, amount: 30, unit: "minutes")

        expect { logger.call }.not_to raise_error
      end
    end

    context "AmountとUnitの処理" do
      it "指定したunitで記録される" do
        logger = described_class.new(log_habit, user, amount: 45, unit: "km")
        result = logger.call

        event = log_habit.task_events.last
        expect(event.amount).to eq 45
        expect(event.unit).to eq "km"
      end

      it "数量が0でも記録される" do
        logger = described_class.new(log_habit, user, amount: 0, unit: "minutes")
        result = logger.call

        expect(result.notice).to eq "記録しました"
        expect(log_habit.task_events.last.amount).to eq 0
      end
    end
  end
end
