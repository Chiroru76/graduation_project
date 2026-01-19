class BondHpLineNotifyJob < ApplicationJob
  queue_as :default

  LOW_BOND_HP = 10

  def perform
    User
      .joins(:active_character)
      .includes(active_character: :character_kind)
      .where(characters: { bond_hp: LOW_BOND_HP, state: :alive })
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
      🚨 #{pet_name}がお腹を空かせています

      いますぐエサをあげてください。🍚

      ーーーーーーーーーーーーーーー
      👉 アプリで確認する: #{dashboard_url}
    TEXT
  end
end
