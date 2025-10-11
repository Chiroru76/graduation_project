class RemoveStageFromCharacters < ActiveRecord::Migration[8.0]
  def change
    remove_column :characters, :stage, :string
  end
end
