require 'rails_helper'

RSpec.describe '称号獲得', type: :system do
  let(:user) { create(:user) }
  let!(:title) { create(:title, key: 'todo_5', name: 'TODO達人', rule_type: 'todo_completion', threshold: 5) }

  before do
    setup_master_data
    setup_character_for_user(user)
    login_as user, scope: :user
  end

  describe 'TODO完了で称号獲得' do
    it '5つのTODOを完了すると称号を獲得する' do
      # 4つ事前に完了
      4.times do
        task = create(:task, :todo, user: user)
        task.complete!(by_user: user)
      end

      # 5つ目を作成
      task5 = create(:task, :todo, user: user, title: '5つ目のTODO')

      visit dashboard_show_path

      # タスクが画面に表示されていることを確認
      expect(page).to have_selector("li#task_#{task5.id}")

      # rack_testではJavaScriptが動作しないため、モデルメソッドを直接呼び出してタスク完了をシミュレート
      # 5つ目を完了すると称号が獲得される
      task5.complete!(by_user: user)

      # 称号獲得チェック（通常はコントローラーで実行されるが、rack_testでは直接呼び出し）
      Titles::Unlocker.new(user: user).call

      # rack_testではTurbo Streamのモーダル表示をテストできないため、
      # 直接プロフィール画面で称号を確認
      visit profile_path

      expect(page).to have_content('TODO達人')
    end
  end
end
