class AddPhotoToLocationPictureXrefs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_picture_xrefs, :photo, :string
  end

  def self.down
    remove_column :location_picture_xrefs, :photo
  end
end
