class AddNumLocationsAddedToUsers < ActiveRecord::Migration[8.1]
  def self.up
    add_column :users, :num_locations_added, :integer
  end

  def self.down
    remove_column :users, :num_locations_added
  end
end
