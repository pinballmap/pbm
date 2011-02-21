class AddLatToRegion < ActiveRecord::Migration
  def self.up
    add_column :regions, :lat, :float
  end

  def self.down
    remove_column :regions, :lat
  end
end
