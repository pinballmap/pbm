class AddZoneIdToLocation < ActiveRecord::Migration[4.2]
  def self.up
    add_column :locations, :zone_id, :integer
  end

  def self.down
    remove_column :locations, :zone_id, :integer
  end
end
