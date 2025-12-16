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

  def show
    @character  = current_user.characters.find(params[:id])
    @appearance = CharacterAppearance.find_by(character_kind: @character.character_kind, pose: :idle)

    # Turbo Frame向けのHTML（<turbo-frame id="character_modal"> ...）を返す
    render partial: "characters/detail_modal",
           locals: { character: @character, appearance: @appearance }
  end

  def feed
    @character = current_user.active_character
    if @character.feed!(current_user)
      redirect_to dashboard_show_path, notice: "えさをあげました！"
    elsif @character.bond_hp >= @character.bond_hp_max
      redirect_to dashboard_show_path, alert: "ペットの幸せ度は最大です"
    elsif
      redirect_to dashboard_show_path, alert: "えさがありません"
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

    # ユーザーの現在育成中ペットをたまごに変更
    current_user.update!(active_character: ch)

    redirect_to welcome_egg_path, notice: "ペットをリセットしました"
  end
end
