class ShareController < ApplicationController
  # 公開ページなので認証は不要にする
  skip_before_action :authenticate_user!, raise: false

   before_action :load_character, only: [ :hatched, :evolved ]

  def hatched
  end

  def evolved
  end

  private

  def load_character
    @user = User.includes(characters: :character_kind).find(params[:id])
    @character = @user.active_character

    @appearance = CharacterAppearance.find_by(
      character_kind: @character.character_kind,
      pose: :idle
    )

    @ogp_image = ogp_image_for(@character, pose: :idle)
  end


  def ogp_image_for(character, pose: :idle)
    kind  = character.character_kind.asset_key
    stage = character.character_kind.stage # egg / child / adult

    # PNG版の OGP 用画像を返す
    "characters/#{kind}/#{kind}_#{stage}_#{pose}.png"
  end
end
