class CharactersController < ApplicationController
  before_action :authenticate_user!

  def feed
    @character = current_user.active_character
    if @character.feed!(current_user)
      redirect_to dashboard_show_path, notice: "えさをあげました！"
    else
      redirect_to dashboard_show_path, alert: "えさをあげられませんでした"
    end
  end
end
