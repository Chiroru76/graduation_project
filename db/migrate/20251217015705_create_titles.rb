class CreateTitles < ActiveRecord::Migration[8.0]
  def change
    create_table :titles do |t|
      t.timestamps
    end
  end
end
