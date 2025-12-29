# spec/factories/mochi_pet_master_setup.rb
FactoryBot.define do
  factory :mochi_pet_master_setup, class: :character_kind do
    # ダミー属性（このfactory自体のレコードは使わない）
    asset_key { "setup" }
    stage { 0 }
    name { "setup" }

    after(:create) do
      kinds = [
        { asset_key: "egg", stage: 0, name: "たまご", appearances: [ :idle ] },
        { asset_key: "green_robo", stage: 1, name: "グリモン", appearances: [ :idle ] },
        { asset_key: "green_robo", stage: 2, name: "グリモン", appearances: [ :idle ] },
        { asset_key: "hurozapple", stage: 1, name: "フロザップル", appearances: [ :idle ] },
        { asset_key: "hurozapple", stage: 2, name: "フロザップル", appearances: [ :idle ] },
      ]

      kinds.each do |data|
        kind = CharacterKind.find_or_create_by!(
          asset_key: data[:asset_key],
          stage: data[:stage]
        ) { |k| k.name = data[:name] }

        data[:appearances].each do |pose|
          CharacterAppearance.find_or_create_by!(
            character_kind: kind,
            pose: pose
          ) { |a| a.asset_kind = :webp }
        end
      end
    end
  end
end
