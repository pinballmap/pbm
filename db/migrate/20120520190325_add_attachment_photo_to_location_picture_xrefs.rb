class AddAttachmentPhotoToLocationPictureXrefs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_picture_xrefs, :photo_file_name, :string
    add_column :location_picture_xrefs, :photo_content_type, :string
    add_column :location_picture_xrefs, :photo_file_size, :integer
    add_column :location_picture_xrefs, :photo_updated_at, :datetime
  end

  def self.down
    remove_column :location_picture_xrefs, :photo_file_name
    remove_column :location_picture_xrefs, :photo_content_type
    remove_column :location_picture_xrefs, :photo_file_size
    remove_column :location_picture_xrefs, :photo_updated_at
  end
end
