class RemovePhotoFromLocationPictureXref < ActiveRecord::Migration
  def up
    remove_column :location_picture_xrefs, :photo
  end

  def down
    add_column :location_picture_xrefs, :photo
  end
end
