class AddIsPrimaryToZone < ActiveRecord::Migration
  def self.up
    add_column :zones, :is_primary, :boolean
  end

  def self.down
    remove_column :zones, :is_primary
  end
end
