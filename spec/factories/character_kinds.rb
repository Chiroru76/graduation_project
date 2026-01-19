FactoryBot.define do
  factory :character_kind do
    name { Faker::Creature::Animal.name }
    stage { :egg }
    sequence(:asset_key) { |n| "test_pet_#{n}" }

    trait :egg do
      stage { :egg }
      asset_key { "egg" }
      name { "たまご" }
    end

    trait :child do
      stage { :child }
    end

    trait :adult do
      stage { :adult }
    end
  end
end
