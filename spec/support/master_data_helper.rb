module MasterDataHelper
  def setup_master_data
    # CharacterKinds
    egg = CharacterKind.find_or_create_by!(asset_key: "egg", stage: :egg) do |k|
      k.name = "たまご"
    end

    child = CharacterKind.find_or_create_by!(asset_key: "green_robo", stage: :child) do |k|
      k.name = "グリモン"
    end

    adult = CharacterKind.find_or_create_by!(asset_key: "green_robo", stage: :adult) do |k|
      k.name = "グリモン"
    end

    # CharacterAppearances
    [egg, child, adult].each do |kind|
      CharacterAppearance.find_or_create_by!(character_kind: kind, pose: :idle) do |a|
        a.asset_kind = :webp
      end
    end
  end

  def setup_character_for_user(user)
    return if user.active_character.present?

    egg_kind = CharacterKind.find_by!(asset_key: "egg", stage: :egg)
    character = user.characters.create!(
      character_kind: egg_kind,
      state: :alive,
      last_activity_at: Time.current,
      level: 1,
      exp: 0
    )
    user.update!(active_character: character)
  end
end
