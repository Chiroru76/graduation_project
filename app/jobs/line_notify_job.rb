class LineNotifyJob < ApplicationJob
  queue_as :default

  def perform
    target_date = Date.tomorrow

    Task
      .where(due_on: target_date, status: :open)
      .includes(:user)
      .group_by(&:user)
      .each do |user, tasks|
      next unless user&.line_user_id.present?

      Line::Notify.send_message(
        user.line_user_id,
        build_message_text(tasks, target_date)
      )
    end
  end

  private

  def build_message_text(tasks, date)
    app_host = Rails.application.config.app_url
    dashboard_url = Rails.application.routes.url_helpers.dashboard_show_url(host: app_host)
    <<~TEXT.strip
      ⏰ 以下のタスクの期限が明日までです。

      期限：#{date.strftime('%Y-%m-%d')}
      #{tasks.each_with_index.map { |t, i| "#{i + 1}. #{t.title}" }.join("\n")}

      ーーーーーーーーーーーーーーー
      👉 アプリで確認する: #{dashboard_url}
    TEXT
  end
end
