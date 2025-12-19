module Titles
  class RuleResolver
    RULE_MAP = {
      "todo_completion"  => Rules::TodoCompletionRule,
      "habit_completion" => Rules::HabitCompletionRule,
      "pet_level"        => Rules::PetLevelRule
    }.freeze

    def self.resolve(title, user:)
      rule_class = RULE_MAP[title.rule_type]

      raise ArgumentError, "Unknown rule_type: #{title.rule_type}" unless rule_class

      rule_class.new(user: user, threshold: title.threshold)
    end
  end
end
