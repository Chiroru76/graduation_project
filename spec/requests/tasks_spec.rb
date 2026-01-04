require "rails_helper"

RSpec.describe "Tasks", type: :request do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
    setup_character_for_user(user)
  end

  # ===== GET /tasks/new (new) =====
  describe "GET /tasks/new" do
    context "新規作成フォームの表示" do
      it "kindパラメータなしでTODOフォームが表示される" do
        get new_task_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("タスク")
      end

      it "kind=todoでTODOフォームが表示される" do
        get new_task_path(kind: "todo")

        expect(response).to have_http_status(:success)
        expect(response.body).to include("タスク")
      end

      it "kind=habitで習慣フォームが表示される" do
        get new_task_path(kind: "habit")

        expect(response).to have_http_status(:success)
        expect(response.body).to include("タスク")
      end

      it "無効なkindはTODOにフォールバックする" do
        get new_task_path(kind: "invalid")

        expect(response).to have_http_status(:success)
      end
    end
  end

  # ===== GET /tasks/:id/edit (edit) =====
  describe "GET /tasks/:id/edit" do
    context "編集フォームの表示" do
      let(:task) { create(:task, user: user, title: "編集対象タスク") }

      it "自分のタスクの編集フォームが表示される" do
        get edit_task_path(task)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("編集対象タスク")
      end

      it "他人のタスクは編集できない" do
        other_user = create(:user)
        other_task = create(:task, user: other_user)

        get edit_task_path(other_task)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ===== POST /tasks (create) =====
  describe "POST /tasks" do
    context "タスクの作成" do
      it "習慣(habit)を作成できる" do
        post tasks_path, params: {
          task: {
            title: "新しい習慣",
            kind: "habit",
            difficulty: "normal",
            tracking_mode: "checkbox",
            reward_exp: 10,
            reward_food_count: 1
          }
        }, headers: { "Accept" => "text/html" }

        # デバッグ出力
        if response.status != 302
          puts "\n=== DEBUG ==="
          puts "Status: #{response.status}"
          puts "Content-Type: #{response.content_type}"
          puts "Full Body:\n#{response.body}"
          puts "============\n"
        end

        expect(response).to redirect_to(dashboard_show_path)

        task = Task.order(:created_at).last
        expect(task).to be_present
        expect(task.title).to eq("新しい習慣")
        expect(task.kind).to eq("habit")
        expect(task.tracking_mode).to eq("checkbox")
        expect(task.user).to eq(user)
      end

      it "TODO(todo)を作成できる" do
        expect {
          post tasks_path, params: {
            task: {
              title: "新しいTODO",
              kind: "todo",
              difficulty: "easy"
            }
          }
        }.to change { Task.count }.by(1)

        task = Task.order(:created_at).last
        expect(task).to be_present
        expect(task.title).to eq("新しいTODO")
        expect(task.kind).to eq("todo")
        expect(task.user).to eq(user)
      end
    end
  end

  # ===== PATCH /tasks/:id (update) =====
  describe "PATCH /tasks/:id" do
    context "タスクの編集" do
      it "タスクのタイトルを編集できる" do
        task = create(:task, user: user, title: "古いタイトル")
        patch task_path(task), params: {
          task: {
            title: "新しいタイトル"
          }
        }

        expect(response).to redirect_to(dashboard_show_path)
        task.reload
        expect(task.title).to eq("新しいタイトル")
      end
    end
  end

  # ===== DELETE /tasks/:id (destroy) =====
  describe "DELETE /tasks/:id" do
    context "タスクの削除" do
      it "作成したタスクを削除できる" do
        task = create(:task, user: user)
        expect {
          delete task_path(task)
        }.to change { Task.count }.by(-1)

        expect(Task.find_by(id: task.id)).to be_nil
      end
    end
  end

  # ===== PATCH /tasks/:id/complete (complete) =====
  describe "PATCH /tasks/:id/complete" do
    context "タスクの完了" do
      it "TODOを完了できる" do
        task = create(:task, :todo, user: user, status: :open)
        patch complete_task_path(task)

        expect(response).to redirect_to(dashboard_show_path)
        follow_redirect!

        expect(response.body).to include("TODOを完了しました")
        task.reload
        expect(task.status).to eq("done")
        expect(task.completed_at).to be_present
      end
    end

    context "ペットコメントの生成 (HTML format)" do
      let(:task) { create(:task, :todo, user: user, status: :open) }
      let(:pet_comment) { "やったね、頑張ったね" }

      before do
        allow(PetComments::Generator).to receive(:for).and_return(pet_comment)
      end

      it "タスク完了時にペットコメントが生成されること" do
        expect(PetComments::Generator).to receive(:for).with(
          :task_completed,
          user: user,
          context: hash_including(
            task_title: task.title,
            difficulty: task.difficulty
          )
        )

        patch complete_task_path(task)
      end

      it "生成されたコメントがflashに保存されること" do
        patch complete_task_path(task)
        follow_redirect!

        expect(flash[:pet_comment]).to eq(pet_comment)
      end
    end

    context "ペットコメントの生成 (Turbo Stream format)" do
      let(:task) { create(:task, :todo, user: user, status: :open) }
      let(:pet_comment) { "いい感じだね" }

      before do
        allow(PetComments::Generator).to receive(:for).and_return(pet_comment)
      end

      it "タスク完了時にペットコメントが生成されること" do
        expect(PetComments::Generator).to receive(:for).with(
          :task_completed,
          user: user,
          context: hash_including(
            task_title: task.title,
            difficulty: task.difficulty
          )
        )

        patch complete_task_path(task), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      it "Turbo Streamレスポンスにpet_comment_areaが含まれること" do
        patch complete_task_path(task), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("pet_comment_area")
        expect(response.body).to include(pet_comment)
      end

      it "flash.nowにペットコメントが設定されること" do
        patch complete_task_path(task), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(controller.flash.now[:pet_comment]).to eq(pet_comment)
      end
    end

    context "ペットコメントが生成されない場合" do
      let(:task) { create(:task, :todo, user: user, status: :open) }

      before do
        allow(PetComments::Generator).to receive(:for).and_return(nil)
      end

      it "flashにpet_commentが設定されないこと" do
        patch complete_task_path(task)

        expect(flash[:pet_comment]).to be_nil
      end
    end

    context "キャラクターが存在しない場合" do
      let(:task) { create(:task, :todo, user: user, status: :open) }

      before do
        user.update!(active_character: nil)
      end

      it "タスクは完了するがペットコメントは生成されないこと" do
        patch complete_task_path(task)

        task.reload
        expect(task.status).to eq("done")
        expect(flash[:pet_comment]).to be_nil
      end
    end

    context "レベルアップ時のペットコメント生成" do
      let(:task) { create(:task, :todo, user: user, status: :open, reward_exp: 150) }
      let(:character) { user.active_character }
      let(:level_up_comment) { "レベルアップしたね" }

      before do
        # 子供のキャラクターに変更（孵化を避けるため）
        child_kind = CharacterKind.find_by!(asset_key: "green_robo", stage: :child)
        character.update!(character_kind: child_kind, level: 2, exp: 200)
        allow(PetComments::Generator).to receive(:for).and_return(level_up_comment)
      end

      it "レベルアップ時にlevel_upイベントでコメントが生成されること" do
        expect(PetComments::Generator).to receive(:for).with(
          :level_up,
          user: user,
          context: {}
        )

        patch complete_task_path(task)
      end

      it "レベルアップコメントがflashに保存されること" do
        patch complete_task_path(task)
        follow_redirect!

        expect(flash[:pet_comment]).to eq(level_up_comment)
      end

      it "Turbo Stream形式でもレベルアップコメントが設定されること" do
        patch complete_task_path(task), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(controller.flash.now[:pet_comment]).to eq(level_up_comment)
      end
    end

    context "進化/孵化時はペットコメントを生成しない" do
      let(:task) { create(:task, :todo, user: user, status: :open, reward_exp: 500) }
      let(:character) { user.active_character }

      before do
        # 卵の状態でレベル1、経験値99に設定（次の経験値で孵化）
        character.update!(level: 1, exp: 99)
        character.character_kind.update!(stage: :egg)
      end

      it "孵化時にはペットコメントが生成されないこと" do
        expect(PetComments::Generator).not_to receive(:for)

        patch complete_task_path(task)
      end
    end
  end

  # ===== POST /tasks/:id/log_amount (log_amount) =====
  describe "POST /tasks/:id/log_amount" do
    context "数量ログ型習慣の数量記録" do
      it "数量ログ型習慣に数量を記録できる" do
        task = create(:task, :habit_log, user: user, status: :open)
        post log_amount_task_path(task), params: {
          amount: 5,
          unit: "回"
        }

        expect(response).to redirect_to(dashboard_show_path)
        follow_redirect!

        expect(response.body).to include("記録しました")
      end
    end

    context "レベルアップ時のペットコメント生成" do
      let(:task) { create(:task, :habit_log, user: user, status: :open, reward_exp: 150) }
      let(:character) { user.active_character }
      let(:level_up_comment) { "やったねレベルアップ" }

      before do
        # 子供のキャラクターに変更（孵化を避けるため）
        child_kind = CharacterKind.find_by!(asset_key: "green_robo", stage: :child)
        character.update!(character_kind: child_kind, level: 2, exp: 200)
        allow(PetComments::Generator).to receive(:for).and_return(level_up_comment)
      end

      it "レベルアップ時にlevel_upイベントでコメントが生成されること" do
        expect(PetComments::Generator).to receive(:for).with(
          :level_up,
          user: user,
          context: {}
        )

        post log_amount_task_path(task), params: { amount: 5, unit: "回" }
      end

      it "Turbo Stream形式でレベルアップコメントが設定されること" do
        post log_amount_task_path(task), params: { amount: 5, unit: "回" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(controller.flash.now[:pet_comment]).to eq(level_up_comment)
        expect(response.body).to include("pet_comment_area")
      end
    end

    context "進化/孵化時はペットコメントを生成しない" do
      let(:task) { create(:task, :habit_log, user: user, status: :open, reward_exp: 500) }
      let(:character) { user.active_character }

      before do
        # 卵の状態でレベル1、経験値99に設定（次の経験値で孵化）
        character.update!(level: 1, exp: 99)
        character.character_kind.update!(stage: :egg)
      end

      it "孵化時にはペットコメントが生成されないこと" do
        expect(PetComments::Generator).not_to receive(:for)

        post log_amount_task_path(task), params: { amount: 5, unit: "回" }
      end
    end
  end
end
