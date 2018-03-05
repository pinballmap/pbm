class AddLocationTypeIdToLocations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :locations, :location_type_id, :integer
  end

  def self.down
    remove_column :locations, :location_type_id
  end
end
