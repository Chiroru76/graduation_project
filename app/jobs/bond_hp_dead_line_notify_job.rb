class BondHpDeadLineNotifyJob < ApplicationJob
  queue_as :default

  def perform
    time_range = 1.day.ago..Time.current

    User
      .joins(:active_character)
      .includes(active_character: :character_kind)
      .where(characters: { state: :dead, dead_at: time_range })
      .where.not(line_user_id: nil)
      .find_each do |user|
      character = user.active_character

      Line::Notify.send_message(
        user.line_user_id,
        build_message_text(character)
      )
    end
  end

  private

  def build_message_text(character)
    app_host = Rails.application.config.app_url
    dashboard_url = Rails.application.routes.url_helpers.dashboard_show_url(host: app_host)
    pet_name = character.character_kind&.name || "ペット"

    <<~TEXT.strip
      🕊️ #{pet_name}が死んでしまいました。

      ⚠️ 次からはこまめにエサをあげてください

      ーーーーーーーーーーーーーーー
      👉 アプリで確認する: #{dashboard_url}
    TEXT
  end
end
