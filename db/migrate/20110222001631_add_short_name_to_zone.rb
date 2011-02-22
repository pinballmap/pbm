class AddShortNameToZone < ActiveRecord::Migration
  def self.up
    add_column :zones, :short_name, :string
  end

  def self.down
    remove_column :zones, :short_name
  end
end
