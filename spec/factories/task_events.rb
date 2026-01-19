FactoryBot.define do
  factory :task_event do
    association :user
    association :task
    association :awarded_character, factory: :character

    task_kind { :todo }
    action { :completed }
    delta { 1 }
    amount { 0 }
    xp_amount { 10 }
    occurred_at { Time.current }

    trait :created do
      action { :created }
      delta { 0 }
      xp_amount { 0 }
    end

    trait :completed do
      action { :completed }
      delta { 1 }
    end

    trait :reopened do
      action { :reopened }
      delta { -1 }
    end

    trait :logged do
      action { :logged }
      task_kind { :habit }
      amount { 5.0 }
      unit { :times }
    end
  end
end
