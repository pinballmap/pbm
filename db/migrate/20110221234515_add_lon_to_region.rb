class AddLonToRegion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :regions, :lon, :float
  end

  def self.down
    remove_column :regions, :lon
  end
end
