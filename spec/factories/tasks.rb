FactoryBot.define do
  factory :task do
    association :user

    title { Faker::Lorem.sentence(word_count: 3) }
    kind { :todo }
    status { :open }
    difficulty { :normal }
    reward_exp { nil } # before_validationで自動設定される
    reward_food_count { rand(1..3) }
    target_value { 5.0 }

    trait :todo do
      kind { :todo }
      tracking_mode { nil }
    end

    trait :habit_checkbox do
      kind { :habit }
      tracking_mode { :checkbox }
    end

    trait :habit_log do
      kind { :habit }
      tracking_mode { :log }
      target_unit { :times }
      target_value { 5.0 }
    end

    trait :easy do
      difficulty { :easy }
    end

    trait :hard do
      difficulty { :hard }
    end

    trait :done do
      status { :done }
      completed_at { Time.current }
    end
  end
end
