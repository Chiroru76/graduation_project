class CreateCharacterAppearances < ActiveRecord::Migration[8.0]
  def change
    create_table :character_appearances do |t|
      t.references :character_kind, null: false, foreign_key: true
      t.integer :pose, null: false, default: 0
      t.integer :asset_kind, null: false, default: 0

      t.timestamps
    end
  end
end
