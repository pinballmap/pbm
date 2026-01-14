class AddPlaceIdToSuggestedLocations < ActiveRecord::Migration[8.1]
  def self.up
    add_column :suggested_locations, :place_id, :string
  end

  def self.down
    remove_column :suggested_locations, :place_id
  end
end
