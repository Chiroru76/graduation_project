# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_13_010514) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "character_appearances", force: :cascade do |t|
    t.bigint "character_kind_id", null: false
    t.integer "pose", default: 0, null: false
    t.integer "asset_kind", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_kind_id"], name: "index_character_appearances_on_character_kind_id"
  end

  create_table "character_kinds", force: :cascade do |t|
    t.string "name", null: false
    t.integer "stage", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "asset_key", null: false
    t.index ["asset_key", "stage"], name: "index_character_kinds_on_asset_key_and_stage", unique: true
    t.index ["name", "stage"], name: "index_character_kinds_on_name_and_stage", unique: true
  end

  create_table "characters", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "character_kind_id", null: false
    t.integer "level", default: 1, null: false
    t.integer "exp", default: 0, null: false
    t.integer "bond_hp", default: 0, null: false
    t.integer "bond_hp_max", default: 100, null: false
    t.integer "state", default: 0, null: false
    t.datetime "last_activity_at"
    t.datetime "dead_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_kind_id"], name: "index_characters_on_character_kind_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "task_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.integer "task_kind", null: false
    t.integer "action", null: false
    t.integer "delta", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "unit", limit: 20
    t.integer "xp_amount", default: 0, null: false
    t.bigint "awarded_character_id"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["awarded_character_id"], name: "index_task_events_on_awarded_character_id"
    t.index ["task_id"], name: "index_task_events_on_task_id"
    t.index ["user_id", "occurred_at"], name: "index_task_events_on_user_id_and_occurred_at"
    t.index ["user_id", "task_kind", "occurred_at"], name: "index_task_events_on_user_id_and_task_kind_and_occurred_at"
    t.index ["user_id"], name: "index_task_events_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.integer "kind", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.date "due_on"
    t.jsonb "repeat_rule", default: {}
    t.integer "reward_exp", default: 0, null: false
    t.integer "reward_food_count", default: 1, null: false
    t.datetime "completed_at"
    t.integer "difficulty", default: 0, null: false
    t.integer "target_unit"
    t.integer "target_period"
    t.decimal "target_value", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tag"
    t.integer "tracking_mode"
    t.index ["kind", "tracking_mode"], name: "index_tasks_on_kind_and_tracking_mode"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", limit: 50, null: false
    t.integer "food_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "character_id"
    t.string "provider"
    t.string "uid"
    t.string "line_user_id"
    t.index ["character_id"], name: "index_users_on_character_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["line_user_id"], name: "index_users_on_line_user_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "character_appearances", "character_kinds"
  add_foreign_key "characters", "character_kinds"
  add_foreign_key "characters", "users"
  add_foreign_key "task_events", "characters", column: "awarded_character_id", on_delete: :nullify
  add_foreign_key "task_events", "tasks", on_delete: :cascade
  add_foreign_key "task_events", "users", on_delete: :cascade
  add_foreign_key "tasks", "users"
  add_foreign_key "users", "characters"
end
