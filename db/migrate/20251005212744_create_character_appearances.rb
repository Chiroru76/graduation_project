class CreateCharacterAppearances < ActiveRecord::Migration[8.0]
  def change
    create_table :character_appearances do |t|
      t.references :character_kind, null: false, foreign_key: true
      t.integer :pose
      t.integer :asset_kind

      t.timestamps
    end
  end
end
