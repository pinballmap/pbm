class AddPlaceIdToLocations < ActiveRecord::Migration[8.1]
  def self.up
    add_column :locations, :place_id, :string
  end

  def self.down
    remove_column :locations, :place_id
  end
end
