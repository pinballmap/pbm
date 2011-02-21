class AddLonToRegion < ActiveRecord::Migration
  def self.up
    add_column :regions, :lon, :float
  end

  def self.down
    remove_column :regions, :lon
  end
end
