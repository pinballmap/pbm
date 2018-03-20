class RemovePhotoFromLocationPictureXref < ActiveRecord::Migration[4.2]
  def up
    remove_column :location_picture_xrefs, :photo
  end

  def down
    add_column :location_picture_xrefs, :photo
  end
end
