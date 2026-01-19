FactoryBot.define do
  factory :character do
    association :user
    association :character_kind

    level { 1 }
    exp { 0 }
    bond_hp { 50 }
    bond_hp_max { 100 }
    state { :alive }
    last_activity_at { Time.current }

    trait :near_hatching do
      level { 1 }
      after(:build) do |character|
        character.exp = Character.threshold_exp_for_next_level(1) - 5
      end
    end

    trait :near_evolution do
      level { 9 }
      after(:build) do |character|
        character.exp = Character.threshold_exp_for_next_level(9) - 5
      end
    end
  end
end
