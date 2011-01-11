class AddFullNameToRegion < ActiveRecord::Migration
  def self.up
    add_column :regions, :full_name, :string
  end

  def self.down
    remove_column :regions, :full_name
  end
end
