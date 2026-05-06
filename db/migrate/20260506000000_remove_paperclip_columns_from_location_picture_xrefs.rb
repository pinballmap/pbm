class RemovePaperclipColumnsFromLocationPictureXrefs < ActiveRecord::Migration[8.1]
  def change
    remove_column :location_picture_xrefs, :photo_file_name, :string
    remove_column :location_picture_xrefs, :photo_content_type, :string
    remove_column :location_picture_xrefs, :photo_file_size, :integer
    remove_column :location_picture_xrefs, :photo_updated_at, :datetime
  end
end
