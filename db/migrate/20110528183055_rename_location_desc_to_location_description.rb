class RenameLocationDescToLocationDescription < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :locations, :desc, :description
  end

  def self.down
    rename_column :locations, :description, :desc
  end
end
