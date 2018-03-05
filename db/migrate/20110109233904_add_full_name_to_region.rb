class AddFullNameToRegion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :regions, :full_name, :string
  end

  def self.down
    remove_column :regions, :full_name
  end
end
