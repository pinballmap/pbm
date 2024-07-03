class AddUserIdToSuggestedLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :suggested_locations, :user_id, :integer
  end
end
