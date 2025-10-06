class DashboardController < ApplicationController
  before_action :authenticate_user!
  def show
    @todos = current_user.tasks.todo.order(:created_at)
    @habits = current_user.tasks.habit.order(:created_at)
    # 現在育成中のキャラクター情報を取得
    character = current_user.active_character
    @appearance = CharacterAppearance.find_by(
      character_kind: character&.character_kind,
      pose: :idle) # とりあえずidleで固定
  end
end
