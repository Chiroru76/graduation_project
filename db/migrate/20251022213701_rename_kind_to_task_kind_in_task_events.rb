class RenameKindToTaskKindInTaskEvents < ActiveRecord::Migration[8.0]
  def change
    rename_column :task_events, :kind, :task_kind
  end
end
