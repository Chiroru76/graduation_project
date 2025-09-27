class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :kind, null: false, default: 0   # enum(todo,habit)
      t.integer :status, null: false, default: 0 # enum(open,done,archived)
      t.date :due_on
      t.jsonb :repeat_rule, default: {}
      t.integer :reward_exp, null: false, default: 0
      t.integer :reward_food_count, null: false, default: 1
      t.datetime :completed_at
      t.integer :difficulty, null: false, default: 0 # enum(easy,normal,hard)
      t.integer :target_unit
      t.integer :target_period
      t.decimal :target_value, precision: 5, scale: 2

      t.timestamps
    end
  end
end
