class AddZoneIdToSuggestedLocations < ActiveRecord::Migration[4.2]
  def change
    add_column :suggested_locations, :zone_id, :integer
  end
end
