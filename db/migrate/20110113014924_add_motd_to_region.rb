class AddMotdToRegion < ActiveRecord::Migration
  def self.up
    add_column :regions, :motd, :string
  end

  def self.down
    remove_column :regions, :motd
  end
end
