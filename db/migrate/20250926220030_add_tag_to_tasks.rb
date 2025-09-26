class AddTagToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :tag, :string
  end
end
