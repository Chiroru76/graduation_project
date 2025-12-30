require 'database_cleaner/active_record'

# test環境でのみDatabaseCleanerを有効化
# development/production環境でのデータ削除を防ぐ
if Rails.env.test?
  RSpec.configure do |config|
    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end

    config.before(:each) do
      DatabaseCleaner.strategy = :transaction
    end

    config.before(:each, type: :system) do
      DatabaseCleaner.strategy = :truncation
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
else
  # test環境以外で実行された場合は警告を表示
  RSpec.configure do |config|
    config.before(:suite) do
      puts "\n⚠️  WARNING: RSpec is running in #{Rails.env} environment!"
      puts "   DatabaseCleaner is DISABLED to protect your data.\n\n"
    end
  end
end
