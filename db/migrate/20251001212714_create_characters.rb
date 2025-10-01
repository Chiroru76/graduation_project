class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :character_kind, null: false, foreign_key: true
      t.integer :level, default: 1, null: false
      t.integer :exp, default: 0 ,null: false
      t.integer :bond_hp, default: 0 ,null: false
      t.integer :bond_hp_max, default: 100, null: false
      t.integer :state, default: 0, null: false
      t.integer :stage, default: 0, null: false
      t.datetime :last_activity_at
      t.datetime :dead_at

      t.timestamps
    end
  end
end
