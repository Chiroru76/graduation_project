class AddTrackingModeToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :tracking_mode, :integer, null: true
    add_index  :tasks, [ :kind, :tracking_mode ]
  end
end
