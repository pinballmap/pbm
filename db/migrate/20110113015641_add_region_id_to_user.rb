class AddRegionIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :region_id, :integer
  end

  def self.down
    remove_column :users, :region_id
  end
end
