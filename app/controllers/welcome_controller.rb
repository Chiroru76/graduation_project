class WelcomeController < ApplicationController
  before_action :authenticate_user!

  def egg
    # 新規登録直後のみアクセス可能
    # unless session.delete(:just_singed_up)
    #     redirect_to dashboard_show_path
    # end

    # 現在育成中のキャラクター情報を取得
    character = current_user.active_character
    @appearance = CharacterAppearance.find_by(
      character_kind: character&.character_kind,
      pose: :idle)
  end
end
