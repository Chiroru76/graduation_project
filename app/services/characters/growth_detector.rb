# frozen_string_literal: true

module Characters
  class GrowthDetector
    # 進化/孵化/レベルアップの条件を定数化
    HATCH_LEVEL = 2
    HATCH_BEFORE_LEVEL = 1
    EVOLVE_LEVEL = 10
    EVOLVE_BEFORE_LEVEL = 9

    attr_reader :character, :before_level, :before_stage

    def initialize(character)
      @character = character
      @before_level = character&.level
      @before_stage = character&.character_kind&.stage
    end

    def detect
      character&.reload
      after_level = character&.level
      after_stage = character&.character_kind&.stage

      {
        hatched: hatched?(after_level, after_stage),
        evolved: evolved?(after_level, after_stage),
        leveled_up: leveled_up?(after_level, after_stage)
      }
    end

    private

    def hatched?(after_level, after_stage)
      stages_ok = before_stage == "egg" && after_stage == "child"
      levels_ok = before_level == HATCH_BEFORE_LEVEL && after_level == HATCH_LEVEL
      stages_ok && levels_ok
    end

    def evolved?(after_level, after_stage)
      stages_ok = before_stage == "child" && after_stage == "adult"
      levels_ok = before_level == EVOLVE_BEFORE_LEVEL && after_level == EVOLVE_LEVEL
      stages_ok && levels_ok
    end

    def leveled_up?(after_level, after_stage)
      return false unless character.present?
      return false unless after_level > before_level
      return false if hatched?(after_level, after_stage) || evolved?(after_level, after_stage)

      true
    end
  end
end
