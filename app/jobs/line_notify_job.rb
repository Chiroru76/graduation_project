class LineNotifyJob
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 5

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
    app_url = Rails.application.config.app_url

    <<~TEXT.strip
      ⏰ 以下のタスクの期限が明日までです。

      期限：#{date.strftime('%Y-%m-%d')}
      #{tasks.each_with_index.map { |t, i| "#{i + 1}. #{t.title}" }.join("\n")}

      アプリで確認する: #{app_url}
    TEXT
  end
end
