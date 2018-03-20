class AddRegionIdToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :region_id, :integer
  end

  def self.down
    remove_column :users, :region_id
  end
end
