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
  end
end
