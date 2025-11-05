class CharacterBondHpDecayJob < ApplicationJob
  queue_as :default

    DAILY_DECAY_AMOUNT = 10 # 毎日減少するきずなHP量
    INACTIVE_DECAY_AMOUNT = 10 # 1日以上活動(タスクの実行orえさやり)が無い場合に減少するきずなHP量

  def perform(*args)
    inactive_since = 1.day.ago

    User.includes(:active_character).find_each do |user|
      character = user.active_character
      next unless character

      total_decay = DAILY_DECAY_AMOUNT

      if character.last_activity_at && character.last_activity_at <= inactive_since
        total_decay += INACTIVE_DECAY_AMOUNT
      end

      new_bond_hp = [ character.bond_hp - total_decay, 0 ].max
      character.update!(bond_hp: new_bond_hp)

      # bond_hpが0になった場合の死亡処理
      if new_bond_hp <= 0 && character.alive?
        character.die!
      end
    end
    Rails.logger.info "[CharacterBondHpDecayJob] processed at #{Time.current}"
  end
end
