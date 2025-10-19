class CharactersController < ApplicationController
  before_action :authenticate_user!

  def index
    @characters = current_user.characters
                              .joins(:character_kind)
                              .where.not(character_kinds: { stage: "egg" }) # 卵は除く
                              .select("DISTINCT ON (character_kinds.id) characters.*")
                              .order("character_kinds.id, characters.created_at DESC")
                              .includes(:character_kind)
  end

  def feed
    @character = current_user.active_character
    if @character.feed!(current_user)
      redirect_to dashboard_show_path, notice: "えさをあげました！"
    else
      redirect_to dashboard_show_path, alert: "えさをあげられませんでした"
    end
  end

  def reset
    # マスターデータからたまごのCharacterKindを取得
    egg_kind = CharacterKind.find_by!(asset_key: "egg")
    # 新しいたまごを作成
    ch = current_user.characters.create!(
        character_kind: egg_kind,
        state: :alive,
        last_activity_at: Time.current
    )

    # ユーザーの現在育成中キャラクターをたまごに変更
    current_user.update!(active_character: ch)

    redirect_to welcome_egg_path, notice: "キャラクターをリセットしました"
  end
end
