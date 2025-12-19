character_kinds = [
  { asset_key: "egg", stage: 0, name: "たまご", appearances: [ :idle ] },
  { asset_key: "green_robo", stage: 1, name: "グリモン", appearances: [ :idle ] },
  { asset_key: "green_robo", stage: 2, name: "グリモン", appearances: [ :idle ] },
  { asset_key: "hurozapple", stage: 1, name: "フロザップル", appearances: [ :idle ] },
  { asset_key: "hurozapple", stage: 2, name: "フロザップル", appearances: [ :idle ] },
  { asset_key: "dreamowl", stage: 1, name: "オウルン", appearances: [ :idle ] },
  { asset_key: "dreamowl", stage: 2, name: "オウルン", appearances: [ :idle ] },
  { asset_key: "lumya", stage: 1, name: "ルミャ", appearances: [ :idle ] },
  { asset_key: "lumya", stage: 2, name: "ルミャ", appearances: [ :idle ] },
  { asset_key: "luna", stage: 1, name: "ルーナ", appearances: [ :idle ] },
  { asset_key: "luna", stage: 2, name: "ルーナ", appearances: [ :idle ] },
  { asset_key: "frame", stage: 1, name: "フレム", appearances: [ :idle ] },
  { asset_key: "frame", stage: 2, name: "フレム", appearances: [ :idle ] }
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

puts "✅ キャラクター種別の登録が完了しました。"
