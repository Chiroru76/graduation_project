require 'capybara/rspec'
require 'selenium-webdriver'

# CI環境の判定
ci_environment = ENV['CI'] == 'true'

if ci_environment
  # CI環境: ローカルのヘッドレスChromeを使用
  Capybara.register_driver :selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1400,1400')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :selenium_chrome_headless
  Capybara.default_max_wait_time = 5

  RSpec.configure do |config|
    config.before(:each, type: :system) do
      driven_by :selenium_chrome_headless
    end
  end
else
  # ローカル開発環境: Selenium Standalone Chromeコンテナへのリモート接続
  Capybara.register_driver :selenium_remote_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1400,1400')

    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: 'http://chrome:4444/wd/hub',
      options: options
    )
  end

  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 3001

  # 許可されたホストリストに明示的に追加
  allowed_hosts = ["web:3001", "web", "0.0.0.0:3001", "127.0.0.1:3001"]
  Rails.application.config.hosts += allowed_hosts

  # リモートブラウザ（chromeコンテナ）からwebコンテナにアクセスするためのホスト名
  Capybara.app_host = "http://web:3001"

  Capybara.javascript_driver = :selenium_remote_chrome
  Capybara.default_max_wait_time = 5

  RSpec.configure do |config|
    config.before(:each, type: :system) do
      driven_by :selenium_remote_chrome
    end
  end
end
