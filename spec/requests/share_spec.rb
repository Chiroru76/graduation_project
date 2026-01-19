require "rails_helper"

RSpec.describe "Share", type: :request do
  before(:all) do
    setup_master_data
  end

  let(:user) { create(:user) }

  before do
    setup_character_for_user(user)
  end

  # ===== GET /share/:id/hatched (hatched) =====
  describe "GET /share/:id/hatched" do
    context "孵化シェアページの表示" do
      it "認証なしで孵化シェアページを表示できる" do
        get share_hatched_path(character_id: user.active_character.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("誕生")
      end

      it "ユーザーのキャラクター情報が表示される" do
        character = user.active_character
        child_kind = CharacterKind.find_by!(stage: :child)
        character.update!(character_kind: child_kind, level: 2)

        get share_hatched_path(character_id: character.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(child_kind.name)
      end

      it "存在しないキャラクターIDは404エラー" do
        get share_hatched_path(character_id: 99_999)

        expect(response).to have_http_status(404)
      end

      it "OGP画像パスが正しく生成される" do
        character = user.active_character

        get share_hatched_path(character_id: character.id)

        expect(response).to have_http_status(:success)
        # OGP metaタグにOGP画像のパスが含まれていることを確認
        expect(response.body).to include('property="og:image"')
        expect(response.body).to include("characters/egg/egg_egg_idle")
      end
    end
  end

  # ===== GET /share/:id/evolved (evolved) =====
  describe "GET /share/:id/evolved" do
    context "進化シェアページの表示" do
      it "認証なしで進化シェアページを表示できる" do
        get share_evolved_path(character_id: user.active_character.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("進化")
      end

      it "ユーザーのキャラクター情報が表示される" do
        character = user.active_character
        adult_kind = CharacterKind.find_by!(stage: :adult)
        character.update!(character_kind: adult_kind, level: 10)

        get share_evolved_path(character_id: character.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(adult_kind.name)
      end

      it "存在しないキャラクターIDは404エラー" do
        get share_evolved_path(character_id: 99_999)

        expect(response).to have_http_status(404)
      end

      it "OGP画像パスが正しく生成される" do
        character = user.active_character

        get share_evolved_path(character_id: character.id)

        expect(response).to have_http_status(:success)
        # OGP metaタグにOGP画像のパスが含まれていることを確認
        expect(response.body).to include('property="og:image"')
        expect(response.body).to include("characters/egg/egg_egg_idle")
      end
    end
  end
end
