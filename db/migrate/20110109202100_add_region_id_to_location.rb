class AddRegionIdToLocation < ActiveRecord::Migration
  def self.up
    add_column :locations, :region_id, :integer
  end

  def self.down
    remove_column :locations, :region_id
  end
end
