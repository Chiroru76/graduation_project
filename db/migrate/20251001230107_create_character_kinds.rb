class CreateCharacterKinds < ActiveRecord::Migration[8.0]
  def change
    create_table :character_kinds do |t|
      t.string :name, null: false
      t.integer :stage, null: false, default: 0
      t.string :thumbnail_url, null: false

      t.timestamps
    end
    add_index :character_kinds, [ :name, :stage ], unique: true
  end
end
