class AddUserIdIndexToLocations < ActiveRecord::Migration[5.2]
  def change
    add_index :locations, :last_updated_by_user_id
  end
end
