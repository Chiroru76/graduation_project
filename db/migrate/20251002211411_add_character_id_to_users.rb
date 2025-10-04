class AddCharacterIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :character, foreign_key: true
  end
end
