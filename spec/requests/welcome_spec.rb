require "rails_helper"

RSpec.describe "Welcome", type: :request do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
    setup_character_for_user(user)
  end

  # ===== GET /welcome/egg (egg) =====
  describe "GET /welcome/egg" do
    context "たまご画面の表示" do
      it "たまご画面を表示できる" do
        get welcome_egg_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("たまご")
      end

      it "キャラクター情報が表示される" do
        character = user.active_character

        get welcome_egg_path

        expect(response).to have_http_status(:success)
        # キャラクター画像が表示されることを確認
        expect(response.body).to include("characters/egg/egg_egg_idle")
      end

      it "未認証の場合はログインページへリダイレクト" do
        sign_out :user

        get welcome_egg_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
