class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.integer :kind
      t.integer :status
      t.date :due_on
      t.jsonb :repeat_rule
      t.integer :reward_exp
      t.integer :reward_food_count
      t.datetime :completed_at
      t.integer :difficulty
      t.integer :target_unit
      t.integer :target_period
      t.decimal :target_value, precision: 5, scale: 2

      t.timestamps
    end
  end
end
