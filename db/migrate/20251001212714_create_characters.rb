class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :character_kind, null: false, foreign_key: true
      t.integer :level
      t.integer :exp
      t.integer :bond_hp
      t.integer :bond_hp_max
      t.integer :state
      t.integer :stage
      t.datetime :last_activity_at
      t.datetime :dead_at

      t.timestamps
    end
  end
end
