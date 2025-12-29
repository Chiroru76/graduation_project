require "rails_helper"

RSpec.describe Task, type: :model do
  # ========== アソシエーション ==========
  describe "associations" do
    describe "user" do
      it "belongs_to :user の関連を持つこと" do
        task = create(:task)
        expect(task.user).to be_a(User)
      end
    end

    describe "task_events" do
      it "has_many :task_events の関連を持つこと" do
        task = create(:task)
        task_event = create(:task_event, task: task, user: task.user)
        expect(task.task_events).to include(task_event)
      end

      it "タスクが削除されるとtask_eventsも削除されること" do
        task = create(:task)
        create(:task_event, task: task, user: task.user)

        expect { task.destroy }.to change { TaskEvent.count }.by(-1)
      end
    end
  end

  # ========== バリデーション ==========
  describe "validations" do
    describe "title" do
      it "必須であること" do
        task = build(:task, title: nil)
        expect(task).not_to be_valid
        expect(task.errors[:title]).to include("を入力してください")
      end

      it "255文字以下である必要があること" do
        task = build(:task, title: "a" * 256)
        expect(task).not_to be_valid
        expect(task.errors[:title]).to include("は255文字以内で入力してください")
      end

      it "255文字は許可されること" do
        task = build(:task, title: "a" * 255)
        expect(task).to be_valid
      end
    end

    describe "difficulty" do
      it "必須であること" do
        task = build(:task, difficulty: nil)
        expect(task).not_to be_valid
        expect(task.errors[:difficulty]).to include("を入力してください")
      end
    end

    describe "tag" do
      it "空白を許可すること" do
        task = build(:task, tag: "")
        expect(task).to be_valid
      end

      it "nilを許可すること" do
        task = build(:task, tag: nil)
        expect(task).to be_valid
      end

      it "50文字以下である必要があること" do
        task = build(:task, tag: "a" * 51)
        expect(task).not_to be_valid
        expect(task.errors[:tag]).to include("は50文字以内で入力してください")
      end
    end

    describe "reward_exp" do
      it "0以上である必要があること" do
        task = create(:task, difficulty: :normal)
        # 保存後にreward_expを直接-1に変更して再バリデーション
        task.update_column(:reward_exp, -1)
        task.reload
        expect(task).not_to be_valid
        expect(task.errors[:reward_exp]).to include("は0以上の値にしてください")
      end

      it "nilを許可すること (before_validationで自動設定されるため実際はnil許可)" do
        # before_validationが動作するため、実際にはnilは自動的に設定される
        task = build(:task, reward_exp: nil)
        # validationが走ると自動的に設定されるため、このテストは実質的な意味がない
        # 代わりに、reward_expがnilから自動設定されることを確認
        task.save
        expect(task.reward_exp).not_to be_nil
      end
    end

    describe "reward_food_count" do
      it "0以上である必要があること" do
        task = build(:task, reward_food_count: -1)
        expect(task).not_to be_valid
        expect(task.errors[:reward_food_count]).to include("は0以上の値にしてください")
      end

      it "nilを許可すること" do
        task = build(:task, reward_food_count: nil)
        expect(task).to be_valid
      end
    end

    describe "tracking_mode" do
      it "habitの場合は必須であること" do
        task = build(:task, kind: :habit, tracking_mode: nil)
        expect(task).not_to be_valid
        expect(task.errors[:tracking_mode]).to include("を入力してください")
      end

      it "todoの場合は不要であること" do
        task = build(:task, kind: :todo, tracking_mode: nil)
        expect(task).to be_valid
      end
    end
  end

  # ========== Enum ==========
  describe "enums" do
    describe "kind" do
      it "todo, habitの値を持つこと" do
        task = create(:task)

        task.update!(kind: :todo, tracking_mode: nil)
        expect(task.todo?).to be true

        task.update!(kind: :habit, tracking_mode: :checkbox)
        expect(task.habit?).to be true
      end

      it "kindの数値マッピングが正しいこと" do
        expect(Task.kinds[:todo]).to eq(0)
        expect(Task.kinds[:habit]).to eq(1)
      end

      it "デフォルト値がtodoであること" do
        task = Task.new(user: create(:user), title: "Test Task", difficulty: :easy)
        expect(task.kind).to eq("todo")
      end
    end

    describe "status" do
      it "open, done, archivedの値を持つこと" do
        task = create(:task)

        task.update!(status: :open)
        expect(task.open?).to be true

        task.update!(status: :done)
        expect(task.done?).to be true

        task.update!(status: :archived)
        expect(task.archived?).to be true
      end

      it "デフォルト値がopenであること" do
        task = Task.new(user: create(:user), title: "Test Task", difficulty: :easy)
        expect(task.status).to eq("open")
      end
    end

    describe "difficulty" do
      it "easy, normal, hardの値を持つこと" do
        task = create(:task)

        task.update!(difficulty: :easy)
        expect(task.easy?).to be true

        task.update!(difficulty: :normal)
        expect(task.normal?).to be true

        task.update!(difficulty: :hard)
        expect(task.hard?).to be true
      end

      it "デフォルト値がeasyであること" do
        task = Task.new(user: create(:user), title: "Test Task")
        expect(task.difficulty).to eq("easy")
      end
    end
  end

  # ========== コールバック ==========
  describe "callbacks" do
    describe "before_validation :assign_reward_exp_by_difficulty" do
      it "難易度easyの場合、reward_expが10に設定されること" do
        task = build(:task, difficulty: :easy, reward_exp: nil)
        task.valid?
        expect(task.reward_exp).to eq(10)
      end

      it "難易度normalの場合、reward_expが20に設定されること" do
        task = build(:task, difficulty: :normal, reward_exp: nil)
        task.valid?
        expect(task.reward_exp).to eq(20)
      end

      it "難易度hardの場合、reward_expが40に設定されること" do
        task = build(:task, difficulty: :hard, reward_exp: nil)
        task.valid?
        expect(task.reward_exp).to eq(40)
      end

      it "難易度が変更されるとreward_expも更新されること" do
        task = create(:task, difficulty: :easy)
        expect(task.reward_exp).to eq(10)

        task.update!(difficulty: :hard)
        expect(task.reward_exp).to eq(40)
      end

      it "難易度変更時にreward_expが手動で設定されている場合でも更新されること" do
        # 実装を確認すると、will_save_change_to_difficulty?がtrueの場合は上書きされる
        task = create(:task, difficulty: :easy)
        task.reward_exp = 100
        task.save!
        expect(task.reward_exp).to eq(100)

        # 難易度を変更すると、reward_expも更新される
        task.update!(difficulty: :hard)
        expect(task.reward_exp).to eq(40)
      end
    end
  end

  # ========== インスタンスメソッド ==========
  describe "#log_created!" do
    it "作成イベントを記録すること" do
      user = create(:user)
      task = create(:task, user: user)

      expect {
        task.log_created!(by_user: user)
      }.to change { TaskEvent.count }.by(1)

      event = TaskEvent.last
      expect(event.action).to eq("created")
      expect(event.delta).to eq(0)
      expect(event.xp_amount).to eq(0)
    end
  end

  describe "#complete!" do
    let(:user) { create(:user) }

    it "TODOタスクを完了できること" do
      task = create(:task, :todo, user: user, difficulty: :normal)

      expect {
        task.complete!(by_user: user)
      }.to change { task.reload.status }.from("open").to("done")

      expect(task.completed_at).to be_present
    end

    it "チェックボックス型習慣を完了できること" do
      task = create(:task, :habit_checkbox, user: user, difficulty: :normal)

      expect {
        task.complete!(by_user: user)
      }.to change { task.reload.status }.from("open").to("done")
    end

    it "完了イベントを記録すること" do
      task = create(:task, user: user, difficulty: :normal)

      expect {
        task.complete!(by_user: user)
      }.to change { TaskEvent.count }.by(1)

      event = TaskEvent.last
      expect(event.action).to eq("completed")
      expect(event.delta).to eq(1)
      expect(event.xp_amount).to eq(20)
    end

    it "ユーザーに食べ物を付与すること" do
      task = create(:task, user: user, reward_food_count: 3)

      expect {
        task.complete!(by_user: user)
      }.to change { user.reload.food_count }.by(3)
    end

    it "キャラクターに経験値を付与すること" do
      character = user.active_character
      task = create(:task, user: user, difficulty: :normal)

      expect {
        task.complete!(by_user: user)
      }.to change { character.reload.exp }.by(20)
    end

    it "award_exp: falseの場合は経験値を付与しないこと" do
      character = user.active_character
      task = create(:task, user: user, difficulty: :normal)

      expect {
        task.complete!(by_user: user, award_exp: false)
      }.not_to change { character.reload.exp }
    end

    it "ログ型習慣では例外を発生させること" do
      task = create(:task, :habit_log, user: user)

      expect {
        task.complete!(by_user: user)
      }.to raise_error("Only for checkbox habits or todos")
    end
  end

  describe "#log!" do
    let(:user) { create(:user) }

    it "ログ型習慣に数量を記録できること" do
      task = create(:task, :habit_log, user: user, difficulty: :normal)

      expect {
        task.log!(by_user: user, amount: 5.0, unit: :times)
      }.to change { TaskEvent.count }.by(1)

      event = TaskEvent.last
      expect(event.action).to eq("logged")
      expect(event.amount).to eq(5.0)
      expect(event.unit).to eq("times")
    end

    it "unitを省略した場合はtarget_unitを使用すること" do
      task = create(:task, :habit_log, user: user, target_unit: :km)

      task.log!(by_user: user, amount: 10.0, unit: nil)

      event = TaskEvent.last
      expect(event.unit).to eq("km")
    end

    it "ユーザーに食べ物を付与すること" do
      task = create(:task, :habit_log, user: user, reward_food_count: 2)

      expect {
        task.log!(by_user: user, amount: 5.0, unit: :times)
      }.to change { user.reload.food_count }.by(2)
    end

    it "キャラクターに経験値を付与すること" do
      character = user.active_character
      task = create(:task, :habit_log, user: user, difficulty: :normal)

      expect {
        task.log!(by_user: user, amount: 5.0, unit: :times)
      }.to change { character.reload.exp }.by(20)
    end

    it "チェックボックス型習慣では例外を発生させること" do
      task = create(:task, :habit_checkbox, user: user)

      expect {
        task.log!(by_user: user, amount: 5.0, unit: :times)
      }.to raise_error("Only for habit log mode")
    end

    it "TODOタスクでは例外を発生させること" do
      task = create(:task, :todo, user: user)

      expect {
        task.log!(by_user: user, amount: 5.0, unit: :times)
      }.to raise_error("Only for habit log mode")
    end
  end

  describe "#reopen!" do
    let(:user) { create(:user) }

    it "完了したタスクを再開できること" do
      task = create(:task, user: user, status: :done, completed_at: Time.current)

      expect {
        task.reopen!(by_user: user)
      }.to change { task.reload.status }.from("done").to("open")

      expect(task.completed_at).to be_nil
    end

    it "再開イベントを記録すること" do
      task = create(:task, user: user, status: :done, difficulty: :normal)

      expect {
        task.reopen!(by_user: user)
      }.to change { TaskEvent.count }.by(1)

      event = TaskEvent.last
      expect(event.action).to eq("reopened")
      expect(event.delta).to eq(-1)
      expect(event.xp_amount).to eq(-20)
    end

    it "経験値を相殺すること" do
      character = user.active_character
      task = create(:task, user: user, status: :done, difficulty: :normal)
      character.update!(exp: 50)

      expect {
        task.reopen!(by_user: user, revert_exp: true)
      }.to change { character.reload.exp }.by(-20)
    end

    it "食べ物を相殺すること" do
      task = create(:task, user: user, status: :done, reward_food_count: 3)
      user.update!(food_count: 10)

      expect {
        task.reopen!(by_user: user, revert_food: true)
      }.to change { user.reload.food_count }.by(-3)
    end

    it "revert_exp: falseの場合は経験値を相殺しないこと" do
      character = user.active_character
      task = create(:task, user: user, status: :done, difficulty: :normal)
      character.update!(exp: 50)

      expect {
        task.reopen!(by_user: user, revert_exp: false)
      }.not_to change { character.reload.exp }
    end

    it "revert_food: falseの場合は食べ物を相殺しないこと" do
      task = create(:task, user: user, status: :done, reward_food_count: 3)
      user.update!(food_count: 10)

      expect {
        task.reopen!(by_user: user, revert_food: false)
      }.not_to change { user.reload.food_count }
    end

    it "既にopenの場合は何もしないこと" do
      task = create(:task, user: user, status: :open)

      expect {
        task.reopen!(by_user: user)
      }.not_to change { TaskEvent.count }

      expect(task.reload.status).to eq("open")
    end
  end

  # ========== 統合テスト ==========
  describe "integration tests" do
    let(:user) { create(:user) }

    it "TODOタスクの完全なライフサイクル: 作成→完了→再開" do
      # 作成
      task = create(:task, :todo, user: user, difficulty: :normal)
      initial_event_count = TaskEvent.count
      task.log_created!(by_user: user)
      expect(TaskEvent.count).to eq(initial_event_count + 1)

      # 完了
      initial_food = user.food_count
      initial_exp = user.active_character.exp

      task.complete!(by_user: user)

      expect(task.reload.status).to eq("done")
      expect(user.reload.food_count).to be > initial_food
      expect(user.active_character.reload.exp).to be > initial_exp
      expect(TaskEvent.count).to eq(initial_event_count + 2)

      # 再開
      task.reopen!(by_user: user)

      expect(task.reload.status).to eq("open")
      expect(user.reload.food_count).to eq(initial_food)
      expect(user.active_character.reload.exp).to eq(initial_exp)
      expect(TaskEvent.count).to eq(initial_event_count + 3)
    end

    it "習慣タスク(ログ型)の記録" do
      task = create(:task, :habit_log, user: user, difficulty: :normal, reward_food_count: 1)
      initial_food = user.food_count
      initial_exp = user.active_character.exp

      # 3回記録
      3.times do
        task.log!(by_user: user, amount: 5.0, unit: :times)
      end

      expect(TaskEvent.where(task: task, action: :logged).count).to eq(3)
      expect(user.reload.food_count).to eq(initial_food + 3)
      expect(user.active_character.reload.exp).to eq(initial_exp + 60) # 20 * 3
    end
  end

  # ========== 基本動作 ==========
  describe "basic functionality" do
    it "有効なファクトリを持つこと" do
      task = build(:task)
      expect(task).to be_valid
    end
  end
end
