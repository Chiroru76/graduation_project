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
      # キャラクターを孵化済み（子供）にして、孵化イベントが発生しないようにする
      character = user.active_character
      child_kind = CharacterKind.find_by!(asset_key: 'green_robo', stage: :child)
      character.update!(character_kind: child_kind, level: 5, exp: 0)

      # 4つ事前に完了
      4.times do
        task = create(:task, :todo, user: user)
        task.complete!(by_user: user)
      end

      # 5つ目を作成
      task5 = create(:task, :todo, user: user, title: '5つ目のTODO')

      visit dashboard_show_path

      # 5つ目のタスクのチェックボックスをクリック
      within("li#task_#{task5.id}") do
        find('input[type="checkbox"]').click
      end

      # Turbo Streamでモーダルが表示される
      sleep 0.5
      expect(page).to have_content('称号を獲得しました')
      expect(page).to have_content('TODO達人')

      # モーダルを閉じる
      click_button '閉じる'

      # プロフィール画面でも称号を確認
      visit profile_path
      expect(page).to have_content('TODO達人')
    end
  end
end
