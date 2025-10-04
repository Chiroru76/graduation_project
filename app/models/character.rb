class Character < ApplicationRecord
  belongs_to :user
  belongs_to :character_kind

  enum :state, { alive: 0, dead: 1 }
  enum :stage, { egg: 0, child: 1, adult: 2 }

  validates :level, numericality: { greater_than_or_equal_to: 1 }
  validates :exp, :bond_hp, :bond_hp_max, numericality: { greater_than_or_equal_to: 0 }
  validates :bond_hp, numericality: { less_than_or_equal_to: :bond_hp_max }

    #レベルアップに必要な経験値の計算式
  def self.threshold_exp_for_next_level(level)
    return 0 if level < 1
    # レベルが上がるごとに値が1.2倍される
    (100 * (1.2 ** (level - 1))).to_i
  end
  # 現在のレベルに到達するのに必要だった累計経験値
  def exp_floor
    self.class.threshold_exp_for_next_level(level - 1)
  end

  # 次のレベルに上がるために必要な累計経験値
  def exp_ceiling
    self.class.threshold_exp_for_next_level(level)
  end

  # 現在のレベルでどれだけ経験値を獲得しているか
  def current_level_exp
    exp - exp_floor
  end

  # 次のレベルに上がるために必要な経験値
  def exp_needed
    exp_ceiling - exp
  end

  # 経験値ゲージの進捗率（％）
  def exp_progress_percentage
    ((current_level_exp.to_f/(exp_ceiling - exp_floor)) * 100).round
  end

end