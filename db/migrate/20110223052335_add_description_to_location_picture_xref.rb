class AddDescriptionToLocationPictureXref < ActiveRecord::Migration
  def self.up
    add_column :location_picture_xrefs, :description, :text
  end

  def self.down
    remove_column :location_picture_xrefs, :description
  end
end
