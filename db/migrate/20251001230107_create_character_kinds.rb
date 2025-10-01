class CreateCharacterKinds < ActiveRecord::Migration[8.0]
  def change
    create_table :character_kinds do |t|
      t.string :name
      t.integer :stage
      t.string :thumbnail_url

      t.timestamps
    end
  end
end
