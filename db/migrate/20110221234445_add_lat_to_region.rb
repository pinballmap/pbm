class AddLatToRegion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :regions, :lat, :float
  end

  def self.down
    remove_column :regions, :lat
  end
end
