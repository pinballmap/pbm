class AddZoneIdToSuggestedLocations < ActiveRecord::Migration
  def change
    add_column :suggested_locations, :zone_id, :integer
  end
end
