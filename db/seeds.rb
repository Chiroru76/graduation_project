# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


character_kinds = [
  { asset_key: "egg", stage: 0, name: "Egg", appearances: [ :idle ] },
  { asset_key: "green_robo", stage: 1, name: "Green Robo", appearances: [ :idle ] },
  { asset_key: "green_monster", stage: 1, name: "Green Monster", appearances: [ :idle ] },
  { asset_key: "hurozapple", stage: 1, name: "フロザップル", appearances: [ :idle ] },
  { asset_key: "hurozapple", stage: 2, name: "フロザップル", appearances: [ :idle ] }
]

character_kinds.each do |data|
  # --- CharacterKind（マスターデータ）の登録 ---
  kind = CharacterKind.find_or_create_by!(
    asset_key: data[:asset_key],
    stage: data[:stage]
  ) do |k|
    k.name = data[:name]
  end

  # --- CharacterAppearance 登録 ---
  data[:appearances].each do |pose|
    CharacterAppearance.find_or_create_by!(
      character_kind: kind,
      pose: pose
    ) do |a|
      a.asset_kind = :webp
    end
  end

  puts "✅ #{kind.name} 登録完了 (#{data[:appearances].join(', ')})"
end
