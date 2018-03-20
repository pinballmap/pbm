class AddDescToLocations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :locations, :desc, :string
  end

  def self.down
    remove_column :locations, :desc
  end
end
