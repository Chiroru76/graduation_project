class CreateTitles < ActiveRecord::Migration[8.0]
  def change
    create_table :titles do |t|
      t.string  :key, null: false
      t.string  :name, null: false
      t.text    :description
      t.string  :rule_type, null: false
      t.integer :threshold, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :titles, :key, unique: true
  end
end
