class DashboardController < ApplicationController
  before_action :authenticate_user!
  def show
    @todos = current_user.tasks.todo.open.order(created_at: :desc)
    @habits = current_user.tasks.habit.order(created_at: :desc)
    # 現在育成中のペット情報を取得
    character = current_user.active_character
    @appearance = CharacterAppearance.find_by(
      character_kind: character&.character_kind,
      pose: :idle
    ) # とりあえずidleで固定
  end
end
