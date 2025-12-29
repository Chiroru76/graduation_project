FactoryBot.define do
  factory :title do
    sequence(:key) { |n| "test_title_#{n}" }
    name { Faker::Lorem.words(number: 3).join(" ") }
    description { Faker::Lorem.sentence }
    rule_type { "todo_completion" }
    threshold { 5 }
    active { true }

    trait :todo_completion do
      rule_type { "todo_completion" }
    end

    trait :habit_completion do
      rule_type { "habit_completion" }
    end
  end
end
