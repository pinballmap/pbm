class AddDefaultSearchTypeToRegion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :regions, :default_search_type, :string
  end

  def self.down
    remove_column :regions, :default_search_type
  end
end
