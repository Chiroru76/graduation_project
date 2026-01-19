class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def line_settings; end
end
