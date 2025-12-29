FactoryBot.define do
  factory :character_appearance do
    association :character_kind
    pose { :idle }
    asset_kind { :webp }

    trait :idle do
      pose { :idle }
    end
  end
end
