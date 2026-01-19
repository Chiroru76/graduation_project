FactoryBot.define do
  factory :user_title do
    association :user
    association :title
    unlocked_at { Time.current }
  end
end
