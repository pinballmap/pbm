class AddMotdToRegion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :regions, :motd, :string
  end

  def self.down
    remove_column :regions, :motd
  end
end
