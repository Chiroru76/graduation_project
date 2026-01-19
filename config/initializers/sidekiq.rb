require "sidekiq"
require "sidekiq-cron"

REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_URL }

  # cronの読み込み
  schedule_path = Rails.root.join("config/schedule.yml")
  Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_path)) if File.exist?(schedule_path)
end

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL }
end
