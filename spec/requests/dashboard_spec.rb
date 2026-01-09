require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
    setup_character_for_user(user)
  end

  # ===== GET /dashboard (show) =====
  describe "GET /dashboard" do
    context "ダッシュボードの表示" do
      it "ダッシュボードページを表示できる" do
        get dashboard_show_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("ホーム")
      end

      it "自分のTODO一覧が表示される" do
        create(:task, :todo, user: user, title: "買い物に行く", status: :open)
        create(:task, :todo, user: user, title: "掃除をする", status: :open)

        get dashboard_show_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("買い物に行く")
        expect(response.body).to include("掃除をする")
      end

      it "完了済みのTODOは表示されない" do
        create(:task, :todo, user: user, title: "未完了TODO", status: :open)
        create(:task, :todo, user: user, title: "完了済みTODO", status: :done)

        get dashboard_show_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("未完了TODO")
        expect(response.body).not_to include("完了済みTODO")
      end

      it "自分の習慣一覧が表示される" do
        create(:task, :habit_checkbox, user: user, title: "ランニング")
        create(:task, :habit_log, user: user, title: "読書")

        get dashboard_show_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("ランニング")
        expect(response.body).to include("読書")
      end

      it "他人のタスクは表示されない" do
        other_user = create(:user)
        create(:task, :todo, user: other_user, title: "他人のタスク")

        get dashboard_show_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("他人のタスク")
      end

      it "キャラクター情報が表示される" do
        character = user.active_character

        get dashboard_show_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(character.character_kind.name)
      end

      it "未認証の場合はログインページへリダイレクト" do
        sign_out :user

        get dashboard_show_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
