require 'capybara/rspec'

# Docker環境ではrack_testドライバーをデフォルトで使用
# JavaScriptが必要なテストのみjs: trueを指定すると、seleniumを使用する試みがされる
Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 5

# システムスペック用の設定
RSpec.configure do |config|
  config.before(:each, type: :system) do |example|
    # js: trueが指定されている場合は警告を出す（Docker環境ではseleniumが使えない）
    if example.metadata[:js]
      warn "WARNING: js: true is specified but Selenium WebDriver is not available in Docker environment. Test may fail."
    end
    # rack_testドライバーを使用
    driven_by :rack_test
  end
end
