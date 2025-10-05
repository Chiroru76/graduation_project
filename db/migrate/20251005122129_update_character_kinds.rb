class UpdateCharacterKinds < ActiveRecord::Migration[8.0]
  def change

    add_column :character_kinds, :asset_key, :string, default: "", null: false

    change_column_default :character_kinds, :asset_key, from: "", to: nil

    add_index :character_kinds, [:asset_key, :stage], unique: true

    remove_column :character_kinds, :thumbnail_url

  end
end
