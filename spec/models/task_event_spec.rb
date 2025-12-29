require "rails_helper"

RSpec.describe TaskEvent, type: :model do
  # ========== アソシエーション ==========
  describe "associations" do
    describe "user" do
      it "belongs_to :user の関連を持つこと" do
        task_event = create(:task_event)
        expect(task_event.user).to be_a(User)
      end
    end

    describe "task" do
      it "belongs_to :task の関連を持つこと" do
        task_event = create(:task_event)
        expect(task_event.task).to be_a(Task)
      end
    end

    describe "awarded_character" do
      it "belongs_to :awarded_character の関連を持つこと (optional)" do
        character = create(:character)
        task_event = create(:task_event, awarded_character: character)
        expect(task_event.awarded_character).to be_a(Character)
      end

      it "awarded_characterがnilでも保存できること" do
        task_event = build(:task_event, awarded_character: nil)
        expect(task_event).to be_valid
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "task_kind" do
      it "必須であること" do
        task_event = build(:task_event, task_kind: nil)
        expect(task_event).not_to be_valid
        expect(task_event.errors[:task_kind]).to include("を入力してください")
      end
    end

    describe "action" do
      it "必須であること" do
        task_event = build(:task_event, action: nil)
        expect(task_event).not_to be_valid
        expect(task_event.errors[:action]).to include("を入力してください")
      end
    end

    describe "delta" do
      it "必須であること" do
        task_event = build(:task_event, delta: nil)
        expect(task_event).not_to be_valid
        expect(task_event.errors[:delta]).to include("を入力してください")
      end

      it "0を許可すること" do
        task_event = build(:task_event, delta: 0)
        expect(task_event).to be_valid
      end

      it "負の値を許可すること" do
        task_event = build(:task_event, delta: -1)
        expect(task_event).to be_valid
      end
    end

    describe "occurred_at" do
      it "必須であること" do
        task_event = build(:task_event, occurred_at: nil)
        expect(task_event).not_to be_valid
        expect(task_event.errors[:occurred_at]).to include("を入力してください")
      end

      it "有効な日時が設定できること" do
        task_event = build(:task_event, occurred_at: Time.current)
        expect(task_event).to be_valid
      end
    end

    describe "amount" do
      it "0以上である必要があること" do
        task_event = build(:task_event, amount: -1)
        expect(task_event).not_to be_valid
        expect(task_event.errors[:amount]).to include("は0以上の値にしてください")
      end

      it "0を許可すること" do
        task_event = build(:task_event, amount: 0)
        expect(task_event).to be_valid
      end

      it "正の値を許可すること" do
        task_event = build(:task_event, amount: 10.5)
        expect(task_event).to be_valid
      end
    end

    describe "xp_amount" do
      it "数値である必要があること" do
        task_event = build(:task_event, xp_amount: "invalid")
        expect(task_event).not_to be_valid
        expect(task_event.errors[:xp_amount]).to include("は数値で入力してください")
      end

      it "負の値を許可すること" do
        task_event = build(:task_event, xp_amount: -10)
        expect(task_event).to be_valid
      end

      it "0を許可すること" do
        task_event = build(:task_event, xp_amount: 0)
        expect(task_event).to be_valid
      end

      it "正の値を許可すること" do
        task_event = build(:task_event, xp_amount: 20)
        expect(task_event).to be_valid
      end
    end
  end

  # ========== Enum ==========
  describe "enums" do
    describe "task_kind" do
      it "todo, habitの値を持つこと" do
        task_event = create(:task_event)

        task_event.update!(task_kind: :todo)
        expect(task_event.todo?).to be true

        task_event.update!(task_kind: :habit)
        expect(task_event.habit?).to be true
      end

      it "task_kindの数値マッピングが正しいこと" do
        expect(TaskEvent.task_kinds[:todo]).to eq(0)
        expect(TaskEvent.task_kinds[:habit]).to eq(1)
      end

      it "デフォルト値がtodoであること" do
        task_event = TaskEvent.new(
          user: create(:user),
          task: create(:task),
          action: :created,
          delta: 0,
          occurred_at: Time.current,
          amount: 0,
          xp_amount: 0
        )
        expect(task_event.task_kind).to eq("todo")
      end
    end

    describe "action" do
      it "created, completed, reopened, loggedの値を持つこと" do
        task_event = create(:task_event)

        task_event.update!(action: :created)
        expect(task_event.created?).to be true

        task_event.update!(action: :completed)
        expect(task_event.completed?).to be true

        task_event.update!(action: :reopened)
        expect(task_event.reopened?).to be true

        task_event.update!(action: :logged)
        expect(task_event.logged?).to be true
      end

      it "actionの数値マッピングが正しいこと" do
        expect(TaskEvent.actions[:created]).to eq(0)
        expect(TaskEvent.actions[:completed]).to eq(1)
        expect(TaskEvent.actions[:reopened]).to eq(2)
        expect(TaskEvent.actions[:logged]).to eq(3)
      end
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      task_event = build(:task_event)
      expect(task_event).to be_valid
    end

    it "すべての必須属性が揃っていれば保存できること" do
      user = create(:user)
      task = create(:task, user: user)
      task_event = TaskEvent.new(
        user: user,
        task: task,
        task_kind: :todo,
        action: :completed,
        delta: 1,
        amount: 0,
        xp_amount: 10,
        occurred_at: Time.current
      )
      expect(task_event.save).to be true
    end

    it "作成イベント(created)を記録できること" do
      user = create(:user)
      task = create(:task, user: user)
      task_event = TaskEvent.create!(
        user: user,
        task: task,
        task_kind: :todo,
        action: :created,
        delta: 0,
        amount: 0,
        xp_amount: 0,
        occurred_at: Time.current
      )

      expect(task_event).to be_persisted
      expect(task_event.created?).to be true
      expect(task_event.delta).to eq(0)
    end

    it "完了イベント(completed)を記録できること" do
      user = create(:user)
      task = create(:task, user: user, difficulty: :normal)
      character = create(:character, user: user)

      task_event = TaskEvent.create!(
        user: user,
        task: task,
        task_kind: :todo,
        action: :completed,
        delta: 1,
        amount: 0,
        xp_amount: 20,
        occurred_at: Time.current,
        awarded_character: character
      )

      expect(task_event).to be_persisted
      expect(task_event.completed?).to be true
      expect(task_event.delta).to eq(1)
      expect(task_event.xp_amount).to eq(20)
      expect(task_event.awarded_character).to eq(character)
    end

    it "取り消しイベント(reopened)を記録できること" do
      user = create(:user)
      task = create(:task, user: user)
      character = create(:character, user: user)

      task_event = TaskEvent.create!(
        user: user,
        task: task,
        task_kind: :todo,
        action: :reopened,
        delta: -1,
        amount: 0,
        xp_amount: -20,
        occurred_at: Time.current,
        awarded_character: character
      )

      expect(task_event).to be_persisted
      expect(task_event.reopened?).to be true
      expect(task_event.delta).to eq(-1)
      expect(task_event.xp_amount).to eq(-20)
    end

    it "記録イベント(logged)を記録できること" do
      user = create(:user)
      task = create(:task, user: user, kind: :habit, tracking_mode: :log)
      character = create(:character, user: user)

      task_event = TaskEvent.create!(
        user: user,
        task: task,
        task_kind: :habit,
        action: :logged,
        delta: 0,
        amount: 5.0,
        unit: "times",
        xp_amount: 10,
        occurred_at: Time.current,
        awarded_character: character
      )

      expect(task_event).to be_persisted
      expect(task_event.logged?).to be true
      expect(task_event.habit?).to be true
      expect(task_event.amount).to eq(5.0)
      expect(task_event.unit).to eq("times")
    end
  end
end
