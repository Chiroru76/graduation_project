class CreateTaskEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :task_events do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :task, null: false, foreign_key: { on_delete: :cascade }

      # Task.kind のスナップショット
      t.integer :kind,   null: false

      # created/completed/reopened/logged 
      t.integer :action, null: false

      # “件数”の純増（完了:+1 / 取り消し:-1 / ログ:+1）
      t.integer :delta,  null: false, default: 0

      # 習慣の“数量”と単位
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.string  :unit, limit: 20

      # 付与XP
      t.integer :xp_amount, null: false, default: 0

      # XPを付与したキャラのスナップショット
      t.bigint :awarded_character_id
      t.foreign_key :characters, column: :awarded_character_id, on_delete: :nullify

      # 発生時刻
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :task_events, [:user_id, :occurred_at]
    add_index :task_events, [:user_id, :kind, :occurred_at]
    add_index :task_events, :awarded_character_id
  end
end
