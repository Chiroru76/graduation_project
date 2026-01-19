module Tasks
  class DailyResetHabitStatusJob < ApplicationJob
    queue_as :default

    def perform
      Task.where(kind: :habit, tracking_mode: :checkbox, status: :done)
        .where("completed_at < ?", Time.zone.now.beginning_of_day)
        .find_each do |task|
        task.update!(status: :open, completed_at: nil)
      end
    end
  end
end
